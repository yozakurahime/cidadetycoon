local sharedConfig = require 'config.shared'

local MissionState = {
    activeMissions = {}, -- [source] = missionData
    sequence = 1000
}

-- Logger helpers
local function DebugLog(text, ...)
    local success, formattedText = pcall(string.format, tostring(text), ...)
    print(string.format("^3[Tycoon:Server:Freelance]^7 %s", success and formattedText or tostring(text)))
end

local function DebugError(text, ...)
    local success, formattedText = pcall(string.format, tostring(text), ...)
    print(string.format("^1[Tycoon-Error:Server:Freelance]^7 %s", success and formattedText or tostring(text)))
end

-- Profile helpers using Core Exports and State Bags
local function getProfile(source)
    local stateProfile = Player(source).state.tycoonProfile
    if stateProfile then return stateProfile end
    return exports.cidade_tycoon_core:GetPlayerProfile(source)
end

local function addXp(source, amount)
    return exports.cidade_tycoon_core:AddExperience(source, amount)
end

local function getActiveVehiclePlateForSource(source)
    local profile = getProfile(source)
    if not profile then return nil, 0 end
    
    local ped = GetPlayerPed(source)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        local plate = GetVehicleNumberPlateText(veh)
        -- Update stored plate if we are in a vehicle
        exports.cidade_tycoon_core:UpdateActivePlate(source, plate)
        return plate, VehToNet(veh)
    end

    -- Fallback to profile's stored plate
    return profile.activePlate, 0
end

-- Core Logic
local function generateMissionStops(mode, count)
    local points = sharedConfig.freelance.points[mode] or {}
    local stops = {}
    
    if #points == 0 then
        -- Fallback se nao houver pontos configurados
        return { { hubName = "Destino Emergencial", coords = vector3(0.0, 0.0, 0.0) } }
    end

    local usedIndexes = {}
    for i = 1, count do
        local idx
        repeat
            idx = math.random(1, #points)
        until not usedIndexes[idx] or #usedIndexes >= #points
        
        usedIndexes[idx] = true
        table.insert(stops, {
            hubName = "Destino #" .. i,
            coords = points[idx],
        })
    end
    return stops
end

local function startFreelanceMissionForSource(source, hubId, modeName, clientVehicleData, contractType)
    DebugLog("Iniciando startFreelanceMissionForSource para source %s", tostring(source))
    local success, result = pcall(function()
        local profile = getProfile(source)
        if not profile then
            DebugError("Perfil nao encontrado para source %s", tostring(source))
            return { ok = false, message = 'Falha ao carregar perfil tycoon.' }
        end

        if profile.isSuspended then
            return { ok = false, message = 'Sua licença tycoon está suspensa. Pague seus impostos na Prefeitura!' }
        end

        if MissionState.activeMissions[source] then
            DebugLog("Jogador %s ja tem missao ativa", profile.citizenid)
            return { ok = false, message = 'Voce ja possui uma missao ativa.' }
        end

        local hub = sharedConfig.hubs[hubId]
        if not hub then
            DebugError("Hub %s nao encontrado no config", tostring(hubId))
            return { ok = false, message = 'Sede logistica invalida.' }
        end

        local activePlate, vehicleNetId = getActiveVehiclePlateForSource(source)
        if not activePlate then
            return { ok = false, message = 'Voce precisa de um veiculo ativo para iniciar esta missao.' }
        end

        -- Detectar Capacidade do Veículo
        local vehicleEntity = NetworkGetEntityFromNetworkId(vehicleNetId)
        local modelHash = GetEntityModel(vehicleEntity)
        local vehData = exports.cidade_tycoon_core:GetVehicleDataByHash(modelHash)
        local capacity = vehData and vehData.capacity or 1
        
        DebugLog("Veiculo detectado: %s | Capacidade: %d", tostring(vehData and vehData.label or "Unknown"), capacity)

        -- Validation logic (Skills/Level/Tutorial)
        local isTutorialMission = false
        if profile.tutorial and profile.tutorial.active then
            local tutorialStep = profile.tutorial.currentStep
            local tutorialHubId = tonumber(profile.tutorial.assignedHubId)

            if tutorialStep ~= 'accept_tutorial_contract' and tutorialStep ~= 'complete_first_delivery' then
                return { ok = false, message = 'Conclua a etapa atual do Guia do Iniciante antes de iniciar contratos.' }
            end

            if modeName ~= 'land' or tutorialHubId ~= hubId then
                return { ok = false, message = ('Seu primeiro contrato deve sair do hub %s em rota terrestre.'):format(profile.tutorial.assignedHubName or 'designado') }
            end

            -- Pegar o modelo do veículo do jogador
            local vehicleEntity = NetworkGetEntityFromNetworkId(vehicleNetId)
            local modelHash = GetEntityModel(vehicleEntity)
            local vehData = exports.cidade_tycoon_core:GetVehicleDataByHash(modelHash)
            local modelName = vehData and vehData.model or 'unknown'

            if tostring(modelName):lower() ~= 'cruiser' then
                return { ok = false, message = 'Use sua cruiser inicial para concluir o contrato guiado.' }
            end

            contractType = 'comum'
            isTutorialMission = true
        end

        if contractType == 'fragile' and (profile.skills.skill_fragile or 0) < 1 then
            return { ok = false, message = 'Requer habilidade Fragil Nivel 1.' }
        end

        -- Setup Mission Scaling
        local playerLevel = profile.level or 1
        local totalRequired = math.min(30, 3 + math.floor(playerLevel / 2))
        local stopsCount = math.min(3, 1 + math.floor(playerLevel / 12))

        -- Tutorial mission is always 1 stop with 5 boxes for simplicity
        if isTutorialMission then
            totalRequired = 5
            stopsCount = 1
        end

        MissionState.sequence = MissionState.sequence + 1
        DebugLog("Gerando %d paradas para modo %s (Total caixas: %d)", stopsCount, tostring(modeName), totalRequired)
        local stops = generateMissionStops(modeName, stopsCount)
        
        if not stops or #stops == 0 then
            DebugError("generateMissionStops retornou vazio ou nil")
            return { ok = false, message = 'Falha ao gerar destinos de entrega.' }
        end

        local mission = {
            missionId = MissionState.sequence,
            citizenId = profile.citizenid,
            mode = modeName,
            contractType = contractType,
            hubId = hubId,
            totalRequired = totalRequired,
            capacity = capacity,
            collectedFromOrigin = 0,
            inTrunk = 0,
            totalDelivered = 0,
            currentStopIndex = 1,
            stops = stops,
            deliveryCoordinates = { x = stops[1].coords.x, y = stops[1].coords.y, z = stops[1].coords.z },
            deliveryRadius = sharedConfig.freelance.deliveryRadius,
            cargoHealth = 100,
            activePlate = activePlate,
            vehicleNetId = vehicleNetId,
            isTutorial = isTutorialMission
        }

        MissionState.activeMissions[source] = mission

        if isTutorialMission then
            advanceTutorialStep(source, 'complete_first_delivery', {
                assignedHubId = hubId,
                tutorialContractId = tostring(mission.missionId),
            })
        end

        DebugLog("Missao #%d iniciada com sucesso para %s. Placa: %s | Capacidade: %d | Tutorial: %s", mission.missionId, profile.citizenid, tostring(activePlate), capacity, tostring(isTutorialMission))

        return {
            ok = true,
            mission = mission
        }
    end)

    if not success then
        DebugError("ERRO CRITICO em startFreelanceMissionForSource: %s", tostring(result))
        return { ok = false, message = 'Erro interno ao processar inicio de missao.' }
    end

    return result
end

local function freightActionForSource(source, clientMissionId, actionName, clientVehicleNetId)
    local mission = MissionState.activeMissions[source]
    if not mission or mission.missionId ~= clientMissionId then
        return { ok = false, message = 'Missao invalida.' }
    end

    if actionName == 'pickup_origin' then
        if mission.collectedFromOrigin >= mission.totalRequired then
            return { ok = false, message = 'Todas as caixas ja foram coletadas com o NPC.' }
        end
        return { ok = true, state = mission }
    elseif actionName == 'load_vehicle' then
        if mission.inTrunk >= mission.capacity then
            return { ok = false, message = 'Veiculo sem espaco suficiente!' }
        end
        
        mission.collectedFromOrigin = mission.collectedFromOrigin + 1
        mission.inTrunk = mission.inTrunk + 1
        
        return { ok = true, state = mission }
    elseif actionName == 'unload_vehicle' then
        if mission.inTrunk <= 0 then
            return { ok = false, message = 'Nao ha carga no veiculo!' }
        end
        return { ok = true, state = mission }
    elseif actionName == 'deliver_box' then
        if mission.inTrunk <= 0 then
            return { ok = false, message = 'Voce nao tem carga para entregar!' }
        end

        mission.inTrunk = mission.inTrunk - 1
        mission.totalDelivered = mission.totalDelivered + 1

        -- Logica de Paradas (Stops)
        local boxesPerStop = math.ceil(mission.totalRequired / #mission.stops)
        
        if (mission.totalDelivered % boxesPerStop == 0) and mission.currentStopIndex < #mission.stops then
            mission.currentStopIndex = mission.currentStopIndex + 1
            local nextStop = mission.stops[mission.currentStopIndex]
            mission.deliveryCoordinates = { x = nextStop.coords.x, y = nextStop.coords.y, z = nextStop.coords.z }
        end

        if mission.totalDelivered >= mission.totalRequired then
            mission.completed = true
        end
        
        return { ok = true, state = mission }
    end

    return { ok = false, message = 'Acao desconhecida.' }
end

local function startPlayerBulkContract(source, hubId, jobId)
    local profile = getProfile(source)
    if not profile then return { ok = false, message = 'Perfil nao encontrado.' } end

    if profile.isSuspended then
        return { ok = false, message = 'Licença suspensa. Regularize seus impostos para aceitar contratos corporativos.' }
    end

    local job = MySQL.single.await('SELECT * FROM tycoon_job_board WHERE id = ?', { jobId })
    if not job or job.status ~= 'posted' then return { ok = false, message = 'Contrato nao disponivel.' } end

    local activePlate, vehicleNetId = getActiveVehiclePlateForSource(source)
    if not activePlate then return { ok = false, message = 'Voce precisa de um veiculo ativo.' } end

    -- Detectar Capacidade do Veículo
    local vehicleEntity = NetworkGetEntityFromNetworkId(vehicleNetId)
    local modelHash = GetEntityModel(vehicleEntity)
    local vehData = exports.cidade_tycoon_core:GetVehicleDataByHash(modelHash)
    local capacity = vehData and vehData.capacity or 1

    -- Mark job as accepted
    MySQL.update.await('UPDATE tycoon_job_board SET status = "accepted", accepted_by = ? WHERE id = ?', { profile.citizenid, jobId })

    local destCoords = json.decode(job.dest_coords)
    local mission = {
        missionId = jobId + 5000, -- Offset for bulk jobs
        isBulk = true,
        jobId = jobId,
        citizenId = profile.citizenid,
        mode = 'land',
        contractType = job.cargo_type,
        hubId = hubId,
        totalRequired = 15, -- Bulk usually requires more boxes
        capacity = capacity,
        collectedFromOrigin = 0,
        inTrunk = 0,
        totalDelivered = 0,
        currentStopIndex = 1,
        stops = { { hubName = "Entrega Corporativa", coords = destCoords } },
        deliveryCoordinates = { x = destCoords.x, y = destCoords.y, z = destCoords.z },
        deliveryRadius = 15.0,
        cargoHealth = 100,
        activePlate = activePlate,
        vehicleNetId = vehicleNetId,
        fixedReward = job.reward
    }

    MissionState.activeMissions[source] = mission
    return { ok = true, mission = mission }
end

local function completeFreelanceMissionForSource(source, clientMissionId, clientVehicleNetId)
    local mission = MissionState.activeMissions[source]
    if not mission or mission.missionId ~= clientMissionId or not mission.completed then
        return false
    end

    local isTutorialCompleted = false
    local tutorialBonus = 0
    if mission.isTutorial then
        isTutorialCompleted = true
        tutorialBonus = 5000
        advanceTutorialStep(source, 'complete_first_delivery', { completed = true })
    end

    local baseReward = mission.fixedReward or (sharedConfig.freelance.baseRewardPerBox[mission.mode] or 1000)
    local mult = mission.fixedReward and 1.0 or (sharedConfig.freelance.rewardMultipliers[mission.contractType] or 1.0)
    
    -- Skill Modifiers from Core
    local skillMult = exports.cidade_tycoon_core:GetTycoonSkillModifier(mission.citizenId, 'freelance_reward_multiplier') or 1.0
    
    -- Integrity Penalty (0.0 to 1.0)
    local integrityFactor = math.max(0.1, (mission.cargoHealth or 100) / 100.0)
    
    local grossReward = math.floor(baseReward * (mission.isBulk and 1 or mission.totalRequired) * mult * skillMult * integrityFactor)
    
    -- Operational Costs (Fuel, Wear, Logistics Fee) - 7% gross
    local operationalCost = math.floor(grossReward * 0.07)
    
    -- Reward Floor (Safety: At least 15% gross)
    local netReward = math.max(math.floor(grossReward * 0.15), grossReward - operationalCost)
    
    local expGained = math.floor(250 * integrityFactor)

    -- Payment
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if player then
        player.Functions.AddMoney('bank', netReward + tutorialBonus, 'tycoon-freelance-payment')
        exports.cidade_tycoon_core:AddExperience(source, expGained)
        exports.cidade_tycoon_core:AddReputation(source, 'general', 10) -- Small completion bonus
        
        -- Log Transaction
        exports.cidade_tycoon_core:LogTransaction(source, netReward + tutorialBonus, 'income', 'freelance', 
            isTutorialCompleted and ('Frete: %s | Bruto: $%d | Custos: -$%d | Bonus Onboarding: +$5000'):format(mission.contractType, grossReward, operationalCost)
            or ('Frete: %s | Bruto: $%d | Custos: -$%d'):format(mission.contractType, grossReward, operationalCost)
        )
    end

    if mission.isBulk then
        MySQL.update.await('UPDATE tycoon_job_board SET status = "completed" WHERE id = ?', { mission.jobId })
    end

    MissionState.activeMissions[source] = nil
    syncMissionToStateBag(source, nil)

    TriggerClientEvent('cidade_tycoon_freelance:client:freelanceMissionCompleted', source, {
        netReward = netReward,
        gainedExperience = expGained,
        cargoIntegrity = mission.cargoHealth or 100,
        operationalCost = operationalCost,
        tutorialCompleted = isTutorialCompleted,
        tutorialBonusCash = tutorialBonus
    })

    return true
end

local function getCompanyAndFreelanceContextForSource(source)
    local profile = getProfile(source)
    local activeMission = MissionState.activeMissions[source]
    local estimatedReward = 0
    
    if activeMission then
        local base = activeMission.fixedReward or (sharedConfig.freelance.baseRewardPerBox[activeMission.mode] or 1000)
        local mult = activeMission.fixedReward and 1.0 or (sharedConfig.freelance.rewardMultipliers[activeMission.contractType] or 1.0)
        estimatedReward = math.floor(base * (activeMission.isBulk and 1 or activeMission.totalRequired) * mult)
    end

    return {
        hasActiveMission = activeMission ~= nil,
        activeMission = activeMission,
        estimatedReward = estimatedReward,
        profile = profile
    }
end

local function getDriverDashboardForSource(source)
    local profile = getProfile(source)
    if not profile then return nil end
    return {
        driver_level = profile.level,
        experience = profile.experience,
        skill_fragile = profile.skills.skill_fragile or 0,
        skill_heavy = profile.skills.skill_heavy or 0,
        skill_hazardous = profile.skills.skill_hazardous or 0,
    }
end

-- Tutorial Logic
local function advanceTutorialStep(source, nextStep, options)
    if nextStep == 'go_to_garage' then
        local profile = getProfile(source)
        if profile and profile.citizenid then
            local existingVehicle = MySQL.single.await('SELECT id FROM player_vehicles WHERE citizenid = ? AND vehicle = ? LIMIT 1', { profile.citizenid, 'cruiser' })
            if not existingVehicle then
                DebugLog("Concedendo cruiser starter para o jogador %s na garagem motelgarage", profile.citizenid)
                local vehicleId, err = exports.qbx_vehicles:CreatePlayerVehicle({
                    citizenid = profile.citizenid,
                    model = 'cruiser',
                    garage = 'motelgarage',
                    props = {
                        engineHealth = 1000,
                        bodyHealth = 1000,
                        fuelLevel = 100,
                    }
                })
                if vehicleId then
                    DebugLog("Cruiser starter criada com sucesso. ID: %s", tostring(vehicleId))
                else
                    DebugError("Erro ao criar cruiser starter para %s: %s", profile.citizenid, err and err.message or "Erro desconhecido")
                end
            end
        end
    end

    local success = exports.cidade_tycoon_core:UpdateTutorialStep(source, nextStep, options)
    if success then
        local profile = getProfile(source)
        return { ok = true, tutorial = profile.tutorial }
    end
    return { ok = false, message = 'Falha ao atualizar tutorial.' }
end

local function handleTutorialVehicleRetrieved(source, modelName, garageName)
    local profile = getProfile(source)
    if not profile or not profile.tutorial.active then return false end

    if tostring(modelName or ''):lower() ~= 'cruiser' then return false end

    if profile.tutorial.currentStep == 'go_to_garage' or profile.tutorial.currentStep == 'retrieve_bike' then
        advanceTutorialStep(source, 'go_to_hub', { assignedGarage = garageName, assignedHubId = 8 })
        return true
    end
    return false
end

local function cancelFreelanceWithFineForSource(source)
    local mission = MissionState.activeMissions[source]
    if not mission then
        return false, 'Voce nao possui nenhuma missao ativa.'
    end

    local fine = 2000
    local success = exports.cidade_tycoon_core:RemoveMoney(source, fine, 'tycoon-freelance-cancel-fine')
    
    if success then
        MissionState.activeMissions[source] = nil
        syncMissionToStateBag(source, nil)
        return true, 'Missao cancelada. Multa de $2.000 aplicada.'
    else
        return false, 'Saldo insuficiente para pagar a multa de cancelamento ($2.000).'
    end
end

-- Callbacks
lib.callback.register('cidade_tycoon_freelance:server:getCompanyAndFreelanceContext', getCompanyAndFreelanceContextForSource)
lib.callback.register('cidade_tycoon_freelance:server:getDriverDashboard', getDriverDashboardForSource)
lib.callback.register('cidade_tycoon_freelance:server:getActiveVehiclePlate', getActiveVehiclePlateForSource)
lib.callback.register('cidade_tycoon_freelance:server:advanceTutorialStep', advanceTutorialStep)

lib.callback.register('cidade_tycoon_freelance:server:trainDriverSkill', function(source, skillKey)
    return exports.cidade_tycoon_core:TrainSkill(source, skillKey)
end)

lib.callback.register('cidade_tycoon_freelance:server:startFreelanceMission', function(source, hubId, modeName, clientVehicleData, contractType)
    return startFreelanceMissionForSource(source, hubId, modeName, clientVehicleData, contractType)
end)

lib.callback.register('cidade_tycoon_freelance:server:startPlayerBulkContract', function(source, hubId, jobId)
    return startPlayerBulkContract(source, hubId, jobId)
end)

lib.callback.register('cidade_tycoon_freelance:server:getSkillModifier', function(source, modifierName)
    return exports.cidade_tycoon_core:GetSkillModifier(source, modifierName)
end)

lib.callback.register('cidade_tycoon_freelance:server:freightAction', function(source, clientMissionId, actionName, clientVehicleNetId)
    return freightActionForSource(source, clientMissionId, actionName, clientVehicleNetId)
end)

lib.callback.register('cidade_tycoon_freelance:server:cancelFreelanceWithFine', cancelFreelanceWithFineForSource)

RegisterNetEvent('cidade_tycoon_freelance:server:completeFreelanceMission', function(clientMissionId, clientVehicleNetId)
    local source = source
    completeFreelanceMissionForSource(source, clientMissionId, clientVehicleNetId)
end)

RegisterNetEvent('cidade_tycoon_freelance:server:failFreelanceMission', function(reason)
    local source = source
    MissionState.activeMissions[source] = nil
    syncMissionToStateBag(source, nil)
end)

-- Exports
local function getSharedPoints(mode)
    return sharedConfig.freelance.points[mode] or {}
end

exports('GetSharedPoints', getSharedPoints)
exports('GetCompanyAndFreelanceContextForSource', getCompanyAndFreelanceContextForSource)
exports('GetDriverDashboardForSource', getDriverDashboardForSource)
exports('GetActiveVehiclePlateForSource', getActiveVehiclePlateForSource)
exports('TrainDriverSkillForSource', function(source, skillKey) return exports.cidade_tycoon_core:TrainSkill(source, skillKey) end)
exports('StartFreelanceMissionForSource', startFreelanceMissionForSource)
exports('StartPlayerBulkContractForSource', startPlayerBulkContract)
exports('FreightActionForSource', freightActionForSource)
exports('CompleteFreelanceMissionForSource', completeFreelanceMissionForSource)
exports('FailFreelanceMissionForSource', function(source, reason) 
    MissionState.activeMissions[source] = nil 
    syncMissionToStateBag(source, nil)
end)

-- Modularized implementations (Legacy bridges removed)
exports('AdvanceTutorialStepForSource', advanceTutorialStep)
exports('HandleTutorialVehicleRetrieved', handleTutorialVehicleRetrieved)
exports('CancelFreelanceWithFineForSource', cancelFreelanceWithFineForSource)
exports('SetActiveVehiclePlate', function(source, plate)
    return exports.cidade_tycoon_core:UpdateActivePlate(source, plate)
end)

AddEventHandler('qbx_core:server:onPlayerLoaded', function(source)
    local mission = MissionState.activeMissions[source]
    if mission then
        syncMissionToStateBag(source, mission)
        DebugLog("Missao ativa re-sincronizada para jogador %d ao conectar.", source)
    end
end)

AddEventHandler('qbx_core:server:onPlayerUnload', function(source)
    MissionState.activeMissions[source] = nil
end)

-- Hooks para automação do gameplay
AddEventHandler('qbx_garages:server:vehicleSpawned', function(veh)
    local source = NetworkGetEntityOwner(veh)
    if not source or source <= 0 then return end

    local plate = GetVehicleNumberPlateText(veh)
    local modelHash = GetEntityModel(veh)
    
    -- Atualiza placa ativa no core
    exports.cidade_tycoon_core:UpdateActivePlate(source, plate)
    
    -- Tenta avançar tutorial se for a bike inicial
    local vehData = exports.qbx_core:GetVehicleData(modelHash)
    local modelName = vehData and vehData.model or "unknown"
    
    handleTutorialVehicleRetrieved(source, modelName, "Garagem")
    DebugLog("Veiculo spawnado detectado para %s. Placa: %s | Modelo: %s", tostring(source), tostring(plate), tostring(modelName))
end)


