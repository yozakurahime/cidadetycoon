local sharedConfig = require 'config.shared'
local MissionState = {
    activeMissions = {}, -- [source] = missionData
    sequence = 1000
}

local function DebugLog(text, ...)
    print(string.format("^3[Tycoon:Server:Freelance]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- SANITIZATION (Guardian Requirement)
-- ==========================================
local function sanitizePlayerMission(source)
    local mission = MissionState.activeMissions[source]
    if mission then
        DebugLog("Limpando missão órfã para o ID %d", source)
        if mission.jobBoardId then
            MySQL.update.await([[UPDATE tycoon_job_board
                SET status = 'posted', assigned_citizenid = NULL
                WHERE id = ? AND status = 'taken' AND assigned_citizenid = ?]],
                { mission.jobBoardId, mission.assignedCitizenId })
        end
        MissionState.activeMissions[source] = nil
    end
end

AddEventHandler('qbx_core:server:onPlayerLoaded', function(source)
    sanitizePlayerMission(source)
end)

AddEventHandler('playerDropped', function()
    sanitizePlayerMission(source)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(1000)
        local ok, err = pcall(function()
            MySQL.update.await("UPDATE tycoon_job_board SET status = 'posted', assigned_citizenid = NULL WHERE status = 'taken'")
        end)
        if not ok then
            print(('^1[Tycoon:Freelance] Falha ao recuperar contratos pendentes: %s^7'):format(tostring(err)))
        end
    end)
end)

-- ==========================================
-- MISSION CORE LOGIC (Server Authoritative)
-- ==========================================

local function getProfile(source)
    return exports.cidade_tycoon_core:GetPlayerProfile(source)
end

local function syncMissionToStateBag(source, missionData)
    local profile = getProfile(source)
    if profile then
        profile.activeMission = missionData
        Player(source).state:set('tycoonProfile', profile, true)
    end
end

local function updateMissionPhase(mission)
    if mission.completed then
        mission.phase = 'completed'
        mission.objective = 'completed'
        return
    end

    local remainingAtOrigin = math.max(0, mission.totalRequired - mission.collectedFromOrigin)
    local remainingToDeliver = math.max(0, mission.totalRequired - mission.totalDelivered)
    local loadTarget = math.min(mission.capacity, remainingToDeliver)
    local deliveryBatchActive = mission.phase == 'delivery'
        and (mission.inTrunk > 0 or mission.carryingSource == 'vehicle')
    local readyForDelivery = not mission.carryingBox and mission.inTrunk > 0
        and (mission.inTrunk >= loadTarget or remainingAtOrigin == 0)

    if deliveryBatchActive or readyForDelivery or mission.carryingSource == 'vehicle'
        or (mission.carryingBox and remainingAtOrigin == 0) then
        mission.phase = 'delivery'
        mission.objective = 'delivery'
    else
        mission.phase = 'pickup'
        mission.objective = 'pickup'
    end
end

local function syncMission(source, mission)
    updateMissionPhase(mission)
    syncMissionToStateBag(source, mission)
    TriggerClientEvent('cidade_tycoon_freelance:client:syncMission', source, mission)
end

local function isPlayerNear(source, coords, maxDistance)
    local ped = GetPlayerPed(source)
    if ped == 0 or not coords then return false end
    return #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z)) <= maxDistance
end

local function decodeCoords(raw)
    if type(raw) == 'string' then
        local ok, decoded = pcall(json.decode, raw)
        if not ok then return nil end
        raw = decoded
    end
    if type(raw) ~= 'table' then return nil end
    local x, y, z = tonumber(raw.x or raw[1]), tonumber(raw.y or raw[2]), tonumber(raw.z or raw[3])
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

local function missionOrigin(mission)
    if mission.originCoords then return mission.originCoords end
    local hub = mission.hubId and sharedConfig.hubs[mission.hubId] or nil
    return hub and hub.coords or nil
end

local function jobBoxCount(cargoType)
    cargoType = string.lower(tostring(cargoType or ''))
    if cargoType:find('heavy', 1, true) or cargoType:find('pesad', 1, true) then return 5 end
    if cargoType:find('frag', 1, true) then return 3 end
    if cargoType:find('hazard', 1, true) or cargoType:find('perigos', 1, true) then return 2 end
    return 3
end

local function validateMissionVehicle(source, mission, vehicleNetId, bindVehicle)
    vehicleNetId = tonumber(vehicleNetId)
    if not vehicleNetId or vehicleNetId <= 0 then return false end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    local ped = GetPlayerPed(source)
    if ped == 0 or vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then return false end
    if #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) > sharedConfig.freelance.unloadVehicleDistance then return false end
    if mission.vehicleNetId and mission.vehicleNetId ~= vehicleNetId then return false end
    if bindVehicle and not mission.vehicleNetId then mission.vehicleNetId = vehicleNetId end
    return true
end

lib.callback.register('cidade_tycoon_freelance:server:startFreelanceMission', function(source, hubId, modeName, _, contractType)
    local profile = getProfile(source)
    if not profile or profile.isSuspended then
        return { ok = false, message = 'Licença suspensa ou perfil não carregado.' }
    end

    if MissionState.activeMissions[source] then
        return { ok = false, message = 'Você já possui uma missão ativa.' }
    end

    local hub = sharedConfig.hubs[hubId]
    if not hub then return { ok = false, message = 'Hub inválido.' } end

    local missionId = MissionState.sequence
    MissionState.sequence = MissionState.sequence + 1

    -- 1. Determine Total Boxes based on Type
    local totalRequired = 1
    if contractType == 'heavy' then
        totalRequired = math.random(5, 10)
    else
        totalRequired = math.random(1, 5)
    end

    -- 2. Determine Number of Delivery Points (1 to 3, depending on volume)
    local numPoints = 1
    if totalRequired > 6 then
        numPoints = math.random(2, 3)
    elseif totalRequired > 3 then
        numPoints = math.random(1, 2)
    end

    -- 3. Select Random Locations and Distribute Boxes
    local deliveryPoints = {}
    local availablePoints = sharedConfig.freelance.points[modeName]
    local shuffledPoints = {}
    for i = 1, #availablePoints do table.insert(shuffledPoints, availablePoints[i]) end
    for i = #shuffledPoints, 2, -1 do
        local j = math.random(i)
        shuffledPoints[i], shuffledPoints[j] = shuffledPoints[j], shuffledPoints[i]
    end

    local boxesLeft = totalRequired
    for i = 1, numPoints do
        local boxesForThisPoint = (i == numPoints) and boxesLeft or math.random(1, math.max(1, math.floor(boxesLeft / (numPoints - i + 1))))
        table.insert(deliveryPoints, {
            coords = shuffledPoints[i],
            required = boxesForThisPoint,
            delivered = 0
        })
        boxesLeft = boxesLeft - boxesForThisPoint
    end

    local mission = {
        missionId = missionId,
        hubId = hubId,
        mode = modeName,
        contractType = contractType or 'standard',
        totalRequired = totalRequired,
        totalDelivered = 0,
        collectedFromOrigin = 0,
        inTrunk = 0,
        carryingBox = false,
        carryingSource = nil,
        vehicleNetId = nil,
        phase = 'pickup',
        objective = 'pickup',
        capacity = (contractType == 'heavy') and 3 or 1, -- Capacidade base do contrato, mas o veículo manda
        cargoHealth = 100,
        startTime = os.time(),
        deliveryPoints = deliveryPoints,
        currentPointIndex = 1 -- Para o cliente saber qual blip mostrar
    }

    MissionState.activeMissions[source] = mission
    syncMission(source, mission)

    if profile.tutorial and profile.tutorial.active then
        if profile.tutorial.currentStep == 'go_to_hub' or profile.tutorial.currentStep == 'accept_tutorial_contract' then
            exports.cidade_tycoon_core:UpdateTutorialStep(source, 'complete_first_delivery')
        end
    end

    return { ok = true, mission = mission }
end)

lib.callback.register('cidade_tycoon_freelance:server:freightAction', function(source, missionId, action, vehicleNetId)
    local mission = MissionState.activeMissions[source]
    if not mission or mission.missionId ~= missionId then return { ok = false } end
    
    if action == 'pickup_origin' then
        local origin = missionOrigin(mission)
        if mission.phase == 'pickup' and not mission.carryingBox
            and isPlayerNear(source, origin, sharedConfig.freelance.pickupOriginDistance)
            and mission.collectedFromOrigin < mission.totalRequired then
            mission.collectedFromOrigin = mission.collectedFromOrigin + 1
            mission.carryingBox = true
            mission.carryingSource = 'origin'
            syncMission(source, mission)
            return { ok = true, state = mission }
        end
    elseif action == 'load_vehicle' then
        if mission.carryingBox and mission.inTrunk < mission.capacity
            and validateMissionVehicle(source, mission, vehicleNetId, true) then
            mission.inTrunk = mission.inTrunk + 1
            mission.carryingBox = false
            mission.carryingSource = nil
            syncMission(source, mission)
            return { ok = true, state = mission }
        end
    elseif action == 'unload_vehicle' then
        local currentPoint = mission.deliveryPoints[mission.currentPointIndex]
        if mission.phase == 'delivery' and not mission.carryingBox and mission.inTrunk > 0
            and isPlayerNear(source, currentPoint and currentPoint.coords, sharedConfig.freelance.serverValidationDistance)
            and validateMissionVehicle(source, mission, vehicleNetId, false) then
            mission.inTrunk = mission.inTrunk - 1
            mission.carryingBox = true
            mission.carryingSource = 'vehicle'
            syncMission(source, mission)
            return { ok = true, state = mission }
        end
    elseif action == 'deliver_box' then
        local currentPoint = mission.deliveryPoints[mission.currentPointIndex]
        if mission.phase == 'delivery' and mission.carryingBox and mission.carryingSource == 'vehicle' and currentPoint
            and isPlayerNear(source, currentPoint.coords, sharedConfig.freelance.serverValidationDistance)
            and currentPoint.delivered < currentPoint.required then
            currentPoint.delivered = currentPoint.delivered + 1
            mission.totalDelivered = mission.totalDelivered + 1
            mission.carryingBox = false
            mission.carryingSource = nil
            
            -- Se completou este ponto, pula para o próximo se houver
            if currentPoint.delivered >= currentPoint.required then
                if mission.currentPointIndex < #mission.deliveryPoints then
                    mission.currentPointIndex = mission.currentPointIndex + 1
                end
            end

            if mission.totalDelivered >= mission.totalRequired then
                mission.completed = true
            end
            syncMission(source, mission)
            return { ok = true, state = mission }
        end
        return { ok = false, message = 'Ponto de entrega já concluído.' }
    end
    return { ok = false, message = 'Ação de carga negada pelo servidor.' }
end)

-- REWARD LOGIC (Server-Authoritative)
RegisterNetEvent('cidade_tycoon_freelance:server:completeFreelanceMission', function(missionId)
    local src = source
    local mission = MissionState.activeMissions[src]
    if not mission or mission.missionId ~= missionId then return end

    if not mission.completed then
        DebugLog("Jogador %d tentou finalizar missão sem entregar todas as caixas!", src)
        return 
    end

    if mission.completing then return end
    mission.completing = true

    local baseReward = 2250
    local mult = (mission.contractType == 'fragile') and 1.4 or (mission.contractType == 'heavy') and 1.8 or (mission.contractType == 'hazardous') and 2.5 or 1.0
    local integrityBonus = mission.cargoHealth / 100
    local finalReward = mission.fixedReward
        and math.floor(math.max(0, mission.fixedReward) * integrityBonus)
        or math.floor(baseReward * mult * integrityBonus)

    if mission.jobBoardId then
        local completed = MySQL.update.await([[UPDATE tycoon_job_board
            SET status = 'completed'
            WHERE id = ? AND status = 'taken' AND assigned_citizenid = ?]],
            { mission.jobBoardId, mission.assignedCitizenId })
        if not completed or completed < 1 then
            mission.completing = false
            return exports.cidade_tycoon_core:NotifyPlayer(src, 'Nao foi possivel validar este contrato.', 'error')
        end
    end

    if not exports.cidade_tycoon_core:AddMoney(src, 'bank', finalReward, 'tycoon-freelance-reward') then
        if mission.jobBoardId then
            MySQL.update.await([[UPDATE tycoon_job_board
                SET status = 'taken'
                WHERE id = ? AND status = 'completed' AND assigned_citizenid = ?]],
                { mission.jobBoardId, mission.assignedCitizenId })
        end
        mission.completing = false
        return exports.cidade_tycoon_core:NotifyPlayer(src, 'O pagamento falhou. Tente concluir novamente.', 'error')
    end
    exports.cidade_tycoon_core:AddExperience(src, 150)
    exports.cidade_tycoon_core:LogTransaction(src, finalReward, 'income', 'freelance', ('Entrega Freelance: %s'):format(mission.contractType))

    -- Tutorial Check
    local profile = getProfile(src)
    if profile and profile.tutorial.active and profile.tutorial.currentStep == 'complete_first_delivery' then
        exports.cidade_tycoon_core:UpdateTutorialStep(src, 'completed')
        exports.cidade_tycoon_core:AddMoney(src, 'bank', 5000, 'tycoon-tutorial-bonus')
        exports.cidade_tycoon_core:NotifyPlayer(src, 'Guia do Iniciante Concluído! Bônus de $5.000 recebido.', 'success')
    end

    MissionState.activeMissions[src] = nil
    syncMissionToStateBag(src, nil)
    exports.cidade_tycoon_core:NotifyPlayer(src, ('Frete finalizado! Recebido: $%d'):format(finalReward), 'success')
end)

lib.callback.register('cidade_tycoon_freelance:server:cancelMission', function(source)
    local mission = MissionState.activeMissions[source]
    if not mission then return { ok = false, message = 'Voce nao possui uma missao ativa.' } end
    if mission.jobBoardId then
        MySQL.update.await([[UPDATE tycoon_job_board
            SET status = 'posted', assigned_citizenid = NULL
            WHERE id = ? AND status = 'taken' AND assigned_citizenid = ?]],
            { mission.jobBoardId, mission.assignedCitizenId })
    end
    MissionState.activeMissions[source] = nil
    syncMissionToStateBag(source, nil)
    TriggerClientEvent('cidade_tycoon_freelance:client:cancelMission', source)
    return { ok = true, message = 'Missao cancelada.' }
end)

-- TUTORIAL SKIP
RegisterCommand('tycoon_skip_tutorial', function(source)
    local profile = getProfile(source)
    if not profile or not profile.tutorial.active then return end
    
    exports.cidade_tycoon_core:UpdateTutorialStep(source, 'completed')
    exports.cidade_tycoon_core:NotifyPlayer(source, 'Você pulou o tutorial Tycoon.', 'inform')
end, false)

exports('AdvanceTutorialStepForSource', function(source, nextStep, options)
    return exports.cidade_tycoon_core:UpdateTutorialStep(source, nextStep, options)
end)

exports('SetActiveVehiclePlate', function(source, plate)
    local profile = getProfile(source)
    if not profile then return end
    exports.cidade_tycoon_core:UpdateProfileField(source, 'active_plate', plate)
end)

exports('HandleTutorialVehicleRetrieved', function(source)
    local profile = getProfile(source)
    if profile and profile.tutorial.active and (profile.tutorial.currentStep == 'retrieve_bike' or profile.tutorial.currentStep == 'get_starter_vehicle') then
        exports.cidade_tycoon_core:UpdateTutorialStep(source, 'go_to_hub')
        exports.cidade_tycoon_core:NotifyPlayer(source, 'Excelente! Agora vá até a PostOP para seu primeiro frete.', 'inform')
    end
end)

exports('GetCompanyAndFreelanceContextForSource', function(source)
    local mission = MissionState.activeMissions[source]
    return {
        hasActiveMission = mission ~= nil,
        activeMission = mission,
        estimatedReward = 2500
    }
end)

exports('StartJobBoardMission', function(source, jobId)
    local profile = getProfile(source)
    if not profile or profile.isSuspended then
        return { ok = false, message = 'Licenca suspensa ou perfil nao carregado.' }
    end
    if MissionState.activeMissions[source] then
        return { ok = false, message = 'Voce ja possui uma missao ativa.' }
    end

    jobId = tonumber(jobId)
    local job = jobId and MySQL.single.await([[SELECT * FROM tycoon_job_board
        WHERE id = ? AND status = 'taken' AND assigned_citizenid = ?]],
        { jobId, profile.citizenid }) or nil
    if not job then return { ok = false, message = 'Contrato indisponivel.' } end

    local origin = decodeCoords(job.origin_coords)
    local destination = decodeCoords(job.dest_coords)
    if not origin or not destination then
        return { ok = false, message = 'Contrato com coordenadas invalidas.' }
    end

    local totalRequired = jobBoxCount(job.cargo_type)
    local mission = {
        missionId = MissionState.sequence,
        hubId = nil,
        originCoords = origin,
        mode = 'job_board',
        contractType = tostring(job.cargo_type or 'standard'),
        title = tostring(job.title or 'Contrato logistico'),
        totalRequired = totalRequired,
        totalDelivered = 0,
        collectedFromOrigin = 0,
        inTrunk = 0,
        carryingBox = false,
        carryingSource = nil,
        vehicleNetId = nil,
        phase = 'pickup',
        objective = 'pickup',
        capacity = math.min(3, totalRequired),
        cargoHealth = 100,
        startTime = os.time(),
        deliveryPoints = {{ coords = destination, required = totalRequired, delivered = 0 }},
        currentPointIndex = 1,
        fixedReward = math.max(0, tonumber(job.reward) or 0),
        jobBoardId = job.id,
        assignedCitizenId = profile.citizenid,
    }
    MissionState.sequence = MissionState.sequence + 1
    MissionState.activeMissions[source] = mission
    syncMission(source, mission)
    return { ok = true, mission = mission, origin = origin }
end)
