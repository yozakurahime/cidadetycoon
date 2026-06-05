print("^5[Tycoon:Client:Freelance]^7 Inicializando script...")

-- Forward declare functions for early export registration
local tryStartFreelance
local startPlayerBulkContractWithValidation

-- Register exports as early as possible
exports('TryStartFreelance', function(...) return tryStartFreelance(...) end)
exports('StartPlayerBulkContractWithValidation', function(...) return startPlayerBulkContractWithValidation(...) end)
exports('GetActiveMissionContext', function()
    return {
        hasActiveMission = ClientRuntimeState.activeMission ~= nil,
        activeMission = ClientRuntimeState.activeMission
    }
end)

-- Alias para o HUD (compatibilidade)
exports('GetCompanyAndFreelanceContextForSource', function()
    return {
        hasActiveMission = ClientRuntimeState.activeMission ~= nil,
        activeMission = ClientRuntimeState.activeMission
    }
end)

function TycoonDebugLog(moduleName, text, ...)
    local debugEnabled = true
    if debugEnabled then
        local side = IsDuplicityVersion() and "Server" or "Client"
        local success, formattedText = pcall(string.format, tostring(text), ...)
        print(string.format("^3[Tycoon:%s:%s]^7 %s", side, tostring(moduleName), success and formattedText or tostring(text)))
    end
end

function TycoonDebugError(moduleName, text, ...)
    local side = IsDuplicityVersion() and "Server" or "Client"
    local success, formattedText = pcall(string.format, tostring(text), ...)
    print(string.format("^1[Tycoon-Error:%s:%s]^7 %s", side, tostring(moduleName), success and formattedText or tostring(text)))
end

function TycoonDebugSuccess(moduleName, text, ...)
    local side = IsDuplicityVersion() and "Server" or "Client"
    local success, formattedText = pcall(string.format, tostring(text), ...)
    print(string.format("^2[Tycoon-Success:%s:%s]^7 %s", side, tostring(moduleName), success and formattedText or tostring(text)))
end

-- Aliases para compatibilidade interna
local DebugLog = TycoonDebugLog
local DebugError = TycoonDebugError
local DebugSuccess = TycoonDebugSuccess

-- ... (helper functions)

local sharedConfig = nil
pcall(function()
    sharedConfig = require 'config.shared'
end)

if not sharedConfig then
    print("^1[Tycoon-Error:Freelance]^7 FALHA CRITICA: Nao foi possivel carregar config/shared.lua via require. Tentando fallback global...^7")
    sharedConfig = TycoonCore and TycoonCore.SharedConfig or {} -- Fallback
end
local refreshTutorialStateFromServer

local ClientRuntimeState = {
    contextCache = nil,
    activeMission = nil,
    deliveryBlip = 0,
    promptVisible = false,
    promptText = nil,
    nextInteractionAt = 0,
}

local boxProp = nil
local getMissionVehicleEntity

local function startCarryingBox()
    local playerPed = PlayerPedId()
    local animDict = "anim@heists@box_carry@"
    RequestAnimDict(animDict)

    local timeout = GetGameTimer() + 4000
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
        if GetGameTimer() > timeout then
            DebugError("freelance", "Erro: Dicionario de animacao nao carregou: %s", animDict)
            return
        end
    end

    local modelHash = joaat("prop_paper_box_01")
    RequestModel(modelHash)
    timeout = GetGameTimer() + 4000
    while not HasModelLoaded(modelHash) do
        Wait(10)
        if GetGameTimer() > timeout then
            DebugError("freelance", "Erro: Modelo do prop nao carregou: prop_paper_box_01")
            return
        end
    end

    ClearPedTasksImmediately(playerPed)
    TaskPlayAnim(playerPed, animDict, "idle", 8.0, -8.0, -1, 49, 0, false, false, false)

    local coords = GetEntityCoords(playerPed)
    boxProp = CreateObject(modelHash, coords.x, coords.y, coords.z, false, false, false)

    local boneIdx = GetPedBoneIndex(playerPed, 28422)
    AttachEntityToEntity(boxProp, playerPed, boneIdx, 0.01, 0.01, 0.1, -10.0, 90.0, 90.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(modelHash)
    DebugSuccess("freelance", "Caixa carregada com sucesso localmente.")
end

local function stopCarryingBox()
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    if boxProp and DoesEntityExist(boxProp) then
        DeleteEntity(boxProp)
    end
    boxProp = nil
end

local function notifyClient(message, notificationType)
    if GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:Notify(message, notificationType or 'inform')
        return
    end

    TriggerEvent('QBCore:Notify', message, notificationType or 'primary')
end

local function showPrompt(text)
    if ClientRuntimeState.promptVisible and ClientRuntimeState.promptText == text then
        -- Refresh native help prompt
        BeginTextCommandDisplayHelp('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayHelp(0, false, true, -1)
        return
    end

    ClientRuntimeState.promptVisible = true
    ClientRuntimeState.promptText = text
    
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function hidePrompt()
    if ClientRuntimeState.promptVisible then
        ClearAllHelpMessages()
        ClientRuntimeState.promptVisible = false
        ClientRuntimeState.promptText = nil
    end
end

local function removeDeliveryBlip()
    if ClientRuntimeState.deliveryBlip ~= 0 and DoesBlipExist(ClientRuntimeState.deliveryBlip) then
        RemoveBlip(ClientRuntimeState.deliveryBlip)
    end

    ClientRuntimeState.deliveryBlip = 0
end

-- Efeitos Imersivos de Carga
local activeHazardousEffect = nil

local function cleanupCargoEffects(veh)
    if activeHazardousEffect then
        StopParticleFxLooped(activeHazardousEffect, 0)
        activeHazardousEffect = nil
    end
    if veh and DoesEntityExist(veh) then
        local m = ClientRuntimeState.activeMission
        if m and m.originalMass then
            SetVehicleHandlingFloat(veh, 'CHandlingData', 'fMass', m.originalMass)
            SetVehicleEnginePowerMultiplier(veh, 1.0)
            ModifyVehicleTopSpeed(veh, 1.0)
        end
    end
end

local function spawnHazardousEffect(veh)
    if activeHazardousEffect then return end
    local dict = "core"
    local particle = "ent_ray_pro_smokey"
    
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do Wait(10) end
    
    UseParticleFxAssetNextCall(dict)
    activeHazardousEffect = StartParticleFxLoopedOnEntity(particle, veh, 0.0, -1.0, 0.5, 0.0, 0.0, 0.0, 1.2, false, false, false)
    SetParticleFxLoopedColour(activeHazardousEffect, 0.2, 0.8, 0.2, 0) -- Greenish chemical smoke
end

local function playFragileImpactSound()
    PlaySoundFrontend(-1, "Glass_Shatter", "VAPID_VEHICLE_SOUNDS", true)
end

local function clearMissionState()
    local vehicle = getMissionVehicleEntity()
    pcall(cleanupCargoEffects, vehicle)
    removeDeliveryBlip()
    ClearAllBlipRoutes()
    stopCarryingBox()
    ClientRuntimeState.activeMission = nil
    ClientRuntimeState.performanceApplied = false
    ClientRuntimeState.performanceAppliedVehicle = nil
    TriggerEvent('cidade_tycoon_tablet:client:hideFreelanceHUD')
    lib.hideTextUI()
end

local function updateFreelanceHUD()
    if not ClientRuntimeState.activeMission then
        TriggerEvent('cidade_tycoon_tablet:client:hideFreelanceHUD')
        lib.hideTextUI()
        return
    end

    local m = ClientRuntimeState.activeMission
    local currentStop = m.stops and m.stops[m.currentStopIndex]
    local stopName = currentStop and (currentStop.hubName or ("Parada " .. m.currentStopIndex)) or "Destino"

    -- Determine current task text
    local taskText = ""
    if m.totalDelivered < m.totalRequired then
        if m.inTrunk > 0 then
            if m.deliveringBox then
                taskText = "Entregue no local azul"
            else
                taskText = ("Descarregue (%d/%d)"):format(m.inTrunk, m.capacity)
            end
        else
            if m.collectedFromOrigin < m.totalRequired then
                if m.carryingBox then
                    taskText = "Leve a carga para o veiculo"
                else
                    taskText = "Volte ao Hub coletar mais"
                end
            else
                taskText = "Dirija até o destino final"
            end
        end
    else
        taskText = "Missao Concluida! Finalize no tablet."
    end

    -- Warning calculation
    local warningText = nil
    local vehicle = getMissionVehicleEntity()

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        warningText = "Procurando veiculo..."
    else
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local vehicleCoords = GetEntityCoords(vehicle)
        local distanceToVeh = #(playerCoords - vehicleCoords)

        if GetVehicleEngineHealth(vehicle) <= 100.0 or GetEntityHealth(vehicle) <= 0 then
            warningText = "VEICULO DESTRUIDO!"
        elseif distanceToVeh > 80.0 then
            warningText = "VEICULO MUITO LONGE!"
        end
    end

    local hudData = {
        active = true,
        contractType = m.contractType,
        loaded = m.loaded,
        inTrunk = m.inTrunk,
        capacity = m.capacity,
        totalDelivered = m.totalDelivered,
        totalRequired = m.totalRequired,
        cargoHealth = m.cargoHealth,
        currentStopIndex = m.currentStopIndex,
        totalStops = m.stops and #m.stops or 1,
        stopName = stopName,
        taskText = taskText,
        mode = m.mode,
        warning = warningText
    }

    TriggerEvent('cidade_tycoon_tablet:client:updateFreelanceHUD', hudData)
end

local function createDeliveryBlip(deliveryCoordinates)
    removeDeliveryBlip()

    local blip = AddBlipForCoord(deliveryCoordinates.x, deliveryCoordinates.y, deliveryCoordinates.z)
    SetBlipSprite(blip, 67)
    SetBlipScale(blip, 0.92)
    SetBlipColour(blip, 5)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 5)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Freelance Transport Tycoon')
    EndTextCommandSetBlipName(blip)

    ClientRuntimeState.deliveryBlip = blip
end

local function fetchCompanyContext()
    DebugLog("freelance", "fetchCompanyContext: Solicitando contexto da empresa e freelance...")
    local context = lib.callback.await('cidade_tycoon_freelance:server:getCompanyAndFreelanceContext', false)
    DebugLog("freelance", "fetchCompanyContext: Contexto retornado pelo servidor: %s", tostring(context and json.encode(context) or "nil"))
    ClientRuntimeState.contextCache = context
    return context
end

local function requestFreightAction(actionName)
    local mission = ClientRuntimeState.activeMission
    if not mission then
        return false
    end

    getMissionVehicleEntity()

    local response = lib.callback.await('cidade_tycoon_freelance:server:freightAction', false, mission.missionId, actionName, mission.vehicleNetId)
    if not response or not response.ok or not response.state then
        notifyClient((response and response.message) or 'O servidor recusou esta interação de carga.', 'error')
        return false
    end

    local state = response.state
    mission.collectedFromOrigin = state.collectedFromOrigin or mission.collectedFromOrigin
    mission.inTrunk = state.inTrunk or mission.inTrunk
    mission.totalDelivered = state.totalDelivered or mission.totalDelivered
    mission.currentStopIndex = state.currentStopIndex or mission.currentStopIndex
    mission.serverCompleted = state.completed == true

    if state.deliveryCoordinates then
        mission.deliveryCoordinates = vector3(state.deliveryCoordinates.x, state.deliveryCoordinates.y, state.deliveryCoordinates.z)
    end

    updateFreelanceHUD()
    return true, state
end

local function getNearestPoint(pointList, playerCoordinates)
    local nearestIndex = nil
    local nearestDistance = nil

    for index = 1, #pointList do
        local pointCoordinates = pointList[index]
        local distance = #(playerCoordinates - pointCoordinates)

        if not nearestDistance or distance < nearestDistance then
            nearestDistance = distance
            nearestIndex = index
        end
    end

    return nearestIndex, nearestDistance
end

local function getNearestFreelancePoint(playerCoordinates)
    local nearestRecord = nil

    local modeOrder = { 'land', 'water', 'air' }
    for i = 1, #modeOrder do
        local modeName = modeOrder[i]
        local pointList = sharedConfig.freelance.points[modeName]
        local nearestIndex, nearestDistance = getNearestPoint(pointList, playerCoordinates)

        if nearestIndex then
            if not nearestRecord or nearestDistance < nearestRecord.distance then
                nearestRecord = {
                    mode = modeName,
                    index = nearestIndex,
                    distance = nearestDistance,
                    coords = pointList[nearestIndex],
                }
            end
        end
    end

    return nearestRecord
end

function tryBuyCompany(hubId)
    local purchaseResponse = lib.callback.await('transport_tycoon_infinito:server:buyCompanyAtPoint', false, hubId)
    if not purchaseResponse then
        notifyClient('Sem resposta do servidor na compra da empresa.', 'error')
        return
    end

    notifyClient(purchaseResponse.message or 'Operação concluída.', purchaseResponse.ok and 'success' or 'error')

    if purchaseResponse.ok then
        fetchCompanyContext()
    end
end

local function getVehicleByPlate(plate, maxDistance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local targetPlate = string.gsub(plate or '', "%s+", ""):lower()

    -- Otimização: Tenta o veículo mais próximo primeiro
    local closest = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, maxDistance, 0, 71)
    if closest ~= 0 then
        local rawPlate = GetVehicleNumberPlateText(closest) or ''
        if string.gsub(rawPlate, "%s+", ""):lower() == targetPlate then
            return closest
        end
    end

    -- Fallback: Varre o pool apenas se o mais próximo falhar
    local vehicles = GetGamePool('CVehicle')
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if DoesEntityExist(vehicle) then
            local vehicleCoords = GetEntityCoords(vehicle)
            if #(playerCoords - vehicleCoords) <= maxDistance then
                local rawPlate = GetVehicleNumberPlateText(vehicle) or ''
                if string.gsub(rawPlate, "%s+", ""):lower() == targetPlate then
                    return vehicle
                end
            end
        end
    end
    return 0
end

local nextVehicleSearchAt = 0
local cachedVehicleEntity = 0

getMissionVehicleEntity = function()
    local m = ClientRuntimeState.activeMission
    if not m then 
        cachedVehicleEntity = 0
        return 0 
    end

    local now = GetGameTimer()
    
    -- 1. Tenta via handle em cache (Fast Path)
    if cachedVehicleEntity ~= 0 and DoesEntityExist(cachedVehicleEntity) then
        return cachedVehicleEntity
    end

    -- 2. Tenta via NetID (Sincronização)
    if m.vehicleNetId and m.vehicleNetId ~= 0 then
        if NetworkDoesNetworkIdExist(m.vehicleNetId) then
            local veh = NetToVeh(m.vehicleNetId)
            if veh ~= 0 and DoesEntityExist(veh) then
                cachedVehicleEntity = veh
                return veh
            end
        end
    end

    -- 3. Fallback via Placa (Slow Path - Throttled)
    if now >= nextVehicleSearchAt then
        nextVehicleSearchAt = now + 2000
        if m.activePlate then
            local found = getVehicleByPlate(m.activePlate, 60.0)
            if found ~= 0 then
                cachedVehicleEntity = found
                if NetworkGetEntityIsNetworked(found) then
                    m.vehicleNetId = VehToNet(found)
                end
                DebugSuccess("freelance", "Veículo recuperado via placa.")
                return found
            end
        end
    end

    return 0
end

function startContractWithValidation(hubId, modeName, contractType)
    DebugLog("freelance", "startContractWithValidation: Iniciando contrato tipo '%s' na sede %s (Modo: %s)", tostring(contractType), tostring(hubId), tostring(modeName))
    
    local playerPed = PlayerPedId()
    local veh = GetVehiclePedIsIn(playerPed, false)
    if veh == 0 then
        notifyClient('Você precisa estar dentro de um veículo Tycoon para aceitar um contrato.', 'error')
        return
    end

    local plate = GetVehicleNumberPlateText(veh)
    local modelHash = GetEntityModel(veh)
    local vehData = exports.cidade_tycoon_core:GetVehicleDataByHash(modelHash)

    -- Validação de Classe vs Modo
    if modeName == 'air' and GetVehicleClass(veh) ~= 15 and GetVehicleClass(veh) ~= 16 then
        notifyClient('Este contrato requer uma Aeronave.', 'error')
        return
    elseif modeName == 'water' and GetVehicleClass(veh) ~= 14 then
        notifyClient('Este contrato requer uma Embarcação.', 'error')
        return
    elseif modeName == 'land' and (GetVehicleClass(veh) == 14 or GetVehicleClass(veh) == 15 or GetVehicleClass(veh) == 16) then
        notifyClient('Este contrato requer um veículo terrestre.', 'error')
        return
    end

    local activePlate = lib.callback.await('cidade_tycoon_freelance:server:getActiveVehiclePlate', false)
    if not activePlate then
        notifyClient('Você não possui nenhum veículo ativo cadastrado na garagem!', 'error')
        return
    end

    local response = lib.callback.await('cidade_tycoon_freelance:server:startFreelanceMission', false, hubId, modeName, nil, contractType)
    if not response or not response.ok or not response.mission then
        notifyClient(response.message or 'Não foi possível iniciar o freelance.', 'error')
        return
    end

    local mission = response.mission
    ClientRuntimeState.activeMission = {
        missionId = mission.missionId,
        mode = mission.mode,
        deliveryCoordinates = vector3(mission.deliveryCoordinates.x, mission.deliveryCoordinates.y, mission.deliveryCoordinates.z),
        deliveryRadius = mission.deliveryRadius,
        vehicleNetId = mission.vehicleNetId,
        vehicleModel = mission.vehicleModel,
        activePlate = activePlate,
        hubId = hubId,
        loaded = false,
        totalRequired = mission.totalRequired,
        capacity = mission.capacity,
        collectedFromOrigin = 0,
        inTrunk = 0,
        totalDelivered = 0,
        stops = mission.stops,
        currentStopIndex = 1,
        contractType = contractType,
        cargoHealth = 100,
        carryingBox = false,
    }

    -- Efeito de Peso para Carga Pesada
    if contractType == 'heavy' then
        local originalMass = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fMass')
        ClientRuntimeState.activeMission.originalMass = originalMass
        
        -- Get Efficiency Modifier
        local efficiency = lib.callback.await('cidade_tycoon_freelance:server:getSkillModifier', false, 'heavy_cargo_efficiency') or 1.0
        local massMult = 1.0 + (0.5 * efficiency) -- Max 1.5x mass, reduced by skill
        local powerMult = 0.75 + (0.15 * (1.0 - efficiency)) -- Better power with skill
        local topSpeedMult = 0.85 + (0.10 * (1.0 - efficiency))

        SetVehicleHandlingFloat(veh, 'CHandlingData', 'fMass', originalMass * massMult)
        SetVehicleEnginePowerMultiplier(veh, powerMult)
        ModifyVehicleTopSpeed(veh, topSpeedMult)
        
        if efficiency < 1.0 then
            notifyClient(('Sua habilidade reduziu a penalidade de peso! (Eficácia: %d%%)'):format(math.floor((1.0 - efficiency) * 100)), 'success')
        else
            notifyClient('Atenção: O peso da carga reduzirá a performance do veículo.', 'inform')
        end
    end

    updateFreelanceHUD()
    notifyClient(('Contrato %s iniciado! Usando veículo de placa %s (Capacidade: %d caixas). Pegue a carga com o NPC.'):format(contractType, activePlate, mission.capacity), 'success')
    fetchCompanyContext()
end

function openFreelanceContractsMenu(hubId, modeName)
    DebugLog("freelance", "openFreelanceContractsMenu: Requisitando getDriverDashboard...")
    local stats = lib.callback.await('cidade_tycoon_freelance:server:getDriverDashboard', false)
    if not stats then
        notifyClient('Não foi possível carregar suas habilidades.', 'error')
        return
    end

    local playerLevel = stats.driver_level or 1
    local tutorialRestricted = tutorialState and tutorialState.active
        and (tutorialState.currentStep == 'accept_tutorial_contract' or tutorialState.currentStep == 'complete_first_delivery')

    local options = {
        {
            title = 'Contrato: Carga Geral',
            description = 'Carga comum. Requisitos: Livre. Recompensa: Base (1.0x).',
            icon = 'box',
            onSelect = function()
                startContractWithValidation(hubId, modeName, 'comum')
            end
        },
        {
            title = 'Contrato: Cargas Frágeis',
            description = (playerLevel >= 3 and stats.skill_fragile >= 1) and 'Eletrônicos/Vidros. Recompensa: +40% (1.4x).' or 'Bloqueado: Requer Nível 3 e Habilidade Frágil.',
            icon = 'glass-water',
            disabled = playerLevel < 3 or stats.skill_fragile < 1,
            onSelect = function()
                startContractWithValidation(hubId, modeName, 'fragile')
            end
        },
        {
            title = 'Contrato: Cargas Valiosas',
            description = (playerLevel >= 6 and stats.skill_heavy >= 1) and 'Ouro/Joias. Recompensa: +80% (1.8x).' or 'Bloqueado: Requer Nível 6 e Habilidade Valiosa.',
            icon = 'gem',
            disabled = playerLevel < 6 or stats.skill_heavy < 1,
            onSelect = function()
                startContractWithValidation(hubId, modeName, 'heavy')
            end
        },
        {
            title = 'Contrato: Cargas Perigosas',
            description = (playerLevel >= 10 and stats.skill_hazardous >= 1) and 'Inflamáveis. Recompensa: +150% (2.5x). Cuidado, EXPLODE!' or 'Bloqueado: Requer Nível 10 e Habilidade Perigosa.',
            icon = 'biohazard',
            disabled = playerLevel < 10 or stats.skill_hazardous < 1,
            onSelect = function()
                startContractWithValidation(hubId, modeName, 'hazardous')
            end
        }
    }

    if tutorialRestricted then
        options[1].description = 'Contrato guiado do onboarding. Use este para concluir sua primeira entrega.'
        for i = 2, #options do
            options[i].description = 'Disponível após concluir o Guia do Iniciante.'
            options[i].disabled = true
        end
    end

    lib.registerContext({
        id = 'tycoon_freelance_contracts',
        title = 'Contratos de Logística Disponíveis',
        options = options
    })
    lib.showContext('tycoon_freelance_contracts')
end

function tryStartFreelance(hubId, modeName)
    DebugLog("freelance", "tryStartFreelance chamado. HubID: %s, Modo: %s", tostring(hubId), tostring(modeName))
    local context = ClientRuntimeState.contextCache or fetchCompanyContext()
    DebugLog("freelance", "Contexto retornado: %s", tostring(context and json.encode(context) or "nil"))
    if not context then
        notifyClient('Falha ao carregar contexto da empresa.', 'error')
        return
    end

    if context.hasActiveMission or ClientRuntimeState.activeMission then
        DebugLog("freelance", "Impedindo tryStartFreelance: missão já ativa.")
        notifyClient('Finalize a corrida atual antes de iniciar outra.', 'error')
        return
    end

    openFreelanceContractsMenu(hubId, modeName)
end

exports('TryStartFreelance', tryStartFreelance)

local function handleFreelanceMissionCompleted(payload)
    DebugLog("freelance", "freelanceMissionCompleted recebido com payload: %s", tostring(payload and json.encode(payload) or "nil"))
    local netReward = payload and payload.netReward or 0
    local gainedExperience = payload and payload.gainedExperience or 0
    local cargoIntegrity = payload and payload.cargoIntegrity or 100
    local operationalCost = payload and payload.operationalCost or 0

    local msg = ('Entrega concluída! Integridade: %d%% | Liquido: +$%d (Custo Logístico: -$%d) | XP: +%d'):format(
        cargoIntegrity, netReward, operationalCost, gainedExperience
    )
    
    if payload and payload.tutorialCompleted then
        msg = msg .. (' | Bônus tutorial: +$%d'):format(payload.tutorialBonusCash or 0)
    end

    notifyClient(msg, 'success')

    clearMissionState()
    fetchCompanyContext()
    refreshTutorialStateFromServer(false)
end

RegisterNetEvent('transport_tycoon_infinito:client:freelanceMissionCompleted', handleFreelanceMissionCompleted)
RegisterNetEvent('cidade_tycoon_freelance:client:freelanceMissionCompleted', handleFreelanceMissionCompleted)

local function handleCancelFreelanceCommand()
    if not ClientRuntimeState.activeMission then
        notifyClient('Não existe freelance ativo para cancelar.', 'error')
        return
    end

    local success, message = lib.callback.await('cidade_tycoon_freelance:server:cancelFreelanceWithFine', false)
    notifyClient(message or 'Não foi possível cancelar o freelance.', success and 'inform' or 'error')
    if success then
        clearMissionState()
    end
end

RegisterCommand('tycoon_cancelar_freela', handleCancelFreelanceCommand, false)
RegisterNetEvent('cidade_tycoon_freelance:client:cancelFreelanceCommand', handleCancelFreelanceCommand)

AddEventHandler('onResourceStop', function(stoppedResource)
    if stoppedResource ~= GetCurrentResourceName() then
        return
    end

    hidePrompt()
    clearMissionState()
end)

CreateThread(function()
    Wait(1500)
    fetchCompanyContext()
end)

CreateThread(function()
    while true do
        local waitMilliseconds = 1000
        local playerPed = PlayerPedId()
        local playerCoordinates = GetEntityCoords(playerPed)
        local currentTimestamp = GetGameTimer()

        if ClientRuntimeState.activeMission then
            local mission = ClientRuntimeState.activeMission
            local playerPed = PlayerPedId()
            local playerCoordinates = GetEntityCoords(playerPed)
            local currentTimestamp = GetGameTimer()

            -- Cache do Veículo
            local vehicle = getMissionVehicleEntity()
            local trunkCoords = vector3(0,0,0)
            local distToTrunk = 999.0

            if vehicle ~= 0 and DoesEntityExist(vehicle) then
                local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
                trunkCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, minDim.y - 0.4, 0.0)
                distToTrunk = #(playerCoordinates - trunkCoords)
            end

            -- GPS Logic: Define para onde o jogador deve ir
            if mission.totalDelivered < mission.totalRequired then
                if mission.inTrunk > 0 then
                    -- Tem carga? Vai para a entrega
                    createDeliveryBlip(mission.deliveryCoordinates)
                else
                    -- Sem carga e falta entregar? Volta pro Hub
                    local hub = sharedConfig.hubs[mission.hubId]
                    if hub then
                        createDeliveryBlip(vector3(hub.coords.x, hub.coords.y, hub.coords.z))
                    end
                end
            end

            -- LÓGICA DE INTERAÇÃO (FASES)
            if mission.totalDelivered < mission.totalRequired then
                -- Fase: Coleta no Hub (NPC)
                if mission.inTrunk < mission.capacity and mission.collectedFromOrigin < mission.totalRequired then
                    local hub = sharedConfig.hubs[mission.hubId]
                    local hubCoords = hub and vector3(hub.coords.x, hub.coords.y, hub.coords.z) or playerCoordinates
                    local distToHub = #(playerCoordinates - hubCoords)

                    if not mission.carryingBox then
                        if distToHub < 30.0 then
                            waitMilliseconds = 0
                            DrawMarker(1, hubCoords.x, hubCoords.y, hubCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 255, 200, 0, 160, false, true, 2, false, nil, nil, false)
                            if distToHub <= 2.2 then
                                showPrompt('Pressione ~INPUT_CONTEXT~ para pegar mercadoria')
                                if (IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38)) and currentTimestamp >= ClientRuntimeState.nextInteractionAt then
                                    ClientRuntimeState.nextInteractionAt = currentTimestamp + 1500
                                    if requestFreightAction('pickup_origin') then
                                        startCarryingBox()
                                        mission.carryingBox = true
                                        notifyClient('Você pegou a mercadoria! Leve-a até a traseira do veículo.', 'success')
                                    end
                                end
                            end
                        end
                    else
                        -- Carregando para o Veículo
                        DisableControlAction(0, 75, true)
                        if IsPedInAnyVehicle(playerPed, false) then
                            stopCarryingBox()
                            mission.carryingBox = false
                            requestFreightAction('drop_box')
                            notifyClient('Você largou a caixa porque entrou em um veículo.', 'error')
                        end

                        if vehicle ~= 0 and DoesEntityExist(vehicle) then
                            if distToTrunk < 30.0 then
                                waitMilliseconds = 0
                                DrawMarker(0, trunkCoords.x, trunkCoords.y, trunkCoords.z + 1.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6, 0.6, 0.6, 0, 255, 0, 100, true, true, 2, false, nil, nil, false)
                                DrawMarker(25, trunkCoords.x, trunkCoords.y, trunkCoords.z + 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 255, 0, 150, false, false, 2, false, nil, nil, false)

                                local interactionDist = (mission.mode == 'land') and 3.5 or 6.0
                                if distToTrunk <= interactionDist then
                                    showPrompt('Pressione ~INPUT_CONTEXT~ para colocar a caixa no veículo')
                                    if (IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38)) and currentTimestamp >= ClientRuntimeState.nextInteractionAt then
                                        ClientRuntimeState.nextInteractionAt = currentTimestamp + 1500
                                        TaskTurnPedToFaceEntity(playerPed, vehicle, 800)
                                        Wait(400)
                                        if lib.progressBar({ duration = 2500, label = 'Colocando mercadoria...', useWhileDead = false, canCancel = false, disable = { move = true, car = true, combat = true }, anim = { dict = 'anim@heists@narcotics@trash', name = 'drop_side' } }) then
                                            local success, newState = requestFreightAction('load_vehicle')
                                            if success then
                                                stopCarryingBox()
                                                mission.carryingBox = false
                                                mission.inTrunk = newState.inTrunk
                                                mission.collectedFromOrigin = newState.collectedFromOrigin

                                                if mission.inTrunk >= mission.capacity or mission.collectedFromOrigin >= mission.totalRequired then
                                                    mission.loaded = true
                                                    notifyClient('Veículo carregado conforme capacidade! Siga para o destino.', 'success')
                                                else
                                                    notifyClient(('Caixa carregada (%d/%d no veículo).'):format(mission.inTrunk, mission.capacity), 'success')
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                elseif mission.inTrunk > 0 then
                    -- Fase: Entrega no Destino
                    local distToDelivery = #(playerCoordinates - mission.deliveryCoordinates)
                    if distToDelivery < 40.0 then
                        waitMilliseconds = 0
                        DrawMarker(1, mission.deliveryCoordinates.x, mission.deliveryCoordinates.y, mission.deliveryCoordinates.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.0, 51, 160, 255, 160, false, true, 2, false, nil, nil, false)
                    end

                    if not mission.deliveringBox then
                        -- Retirar do Veículo
                        if vehicle ~= 0 and DoesEntityExist(vehicle) then
                            local distVehToDelivery = #(GetEntityCoords(vehicle) - mission.deliveryCoordinates)
                            if distVehToDelivery <= 25.0 then
                                if distToTrunk < 30.0 then
                                    waitMilliseconds = 0
                                    DrawMarker(0, trunkCoords.x, trunkCoords.y, trunkCoords.z + 1.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.8, 255, 200, 0, 160, true, true, 2, false, nil, nil, false)

                                    local interactionDist = (mission.mode == 'land') and 3.5 or 6.0
                                    if distToTrunk <= interactionDist and not IsPedInAnyVehicle(playerPed, false) then
                                        showPrompt(('Pressione ~INPUT_CONTEXT~ para retirar a carga (%d no veículo)'):format(mission.inTrunk))
                                        if (IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38)) and currentTimestamp >= ClientRuntimeState.nextInteractionAt then
                                            ClientRuntimeState.nextInteractionAt = currentTimestamp + 1500
                                            if requestFreightAction('unload_vehicle') then
                                                startCarryingBox()
                                                mission.deliveringBox = true
                                                notifyClient('Carga retirada! Leve-a ao ponto azul.', 'success')
                                            end
                                        end
                                    end
                                end
                            else
                                if distToDelivery < 40.0 then
                                    showPrompt('Estacione mais perto do destino')
                                end
                            end
                        end
                    else
                        -- Entregar no Ponto Azul
                        DisableControlAction(0, 75, true)
                        if #(playerCoordinates - mission.deliveryCoordinates) <= 2.2 then
                            waitMilliseconds = 0
                            showPrompt('Pressione ~INPUT_CONTEXT~ para entregar a mercadoria')
                            if (IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38)) and currentTimestamp >= ClientRuntimeState.nextInteractionAt then
                                ClientRuntimeState.nextInteractionAt = currentTimestamp + 1500
                                if lib.progressBar({ duration = 2000, label = 'Entregando...', useWhileDead = false, canCancel = false, disable = { move = true, car = true, combat = true }, anim = { dict = 'anim@heists@narcotics@trash', name = 'drop_side' } }) then
                                    local success, newState = requestFreightAction('deliver_box')
                                    if success then
                                        stopCarryingBox()
                                        mission.deliveringBox = false
                                        mission.inTrunk = newState.inTrunk
                                        mission.totalDelivered = newState.totalDelivered
                                        mission.currentStopIndex = newState.currentStopIndex
                                        mission.serverCompleted = newState.completed == true

                                        if mission.serverCompleted then
                                            TriggerServerEvent('cidade_tycoon_freelance:server:completeFreelanceMission', mission.missionId, mission.vehicleNetId)
                                        elseif mission.inTrunk == 0 then
                                            mission.loaded = false -- Volta para fase de carregamento (seja proxima parada ou volta ao hub)
                                            if mission.totalDelivered < mission.totalRequired then
                                                notifyClient('Carga do veículo esgotada! Volte ao Hub buscar o restante.', 'inform')
                                            end
                                        else
                                            notifyClient('Caixa entregue! Retire a próxima do veículo.', 'success')
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            hidePrompt()
        end

          Wait(waitMilliseconds)
     end
end)

-- ==========================================
-- ESTADO DE TUTORIAL COMPARTILHADO COM O TABLET
-- ==========================================

local tutorialState = nil
local tutorialGuidanceSignature = nil

local function getTutorialGuidanceSignature(tutorial)
    if not tutorial then return 'none' end

    return table.concat({
        tostring(tutorial.currentStep or 'none'),
        tostring(tutorial.assignedGarage or 'none'),
        tostring(tutorial.assignedHubId or 'none'),
        tostring(tutorial.completedAt or 'none'),
    }, ':')
end

local function getTutorialGarageWaypoint(garageName)
    local garages = lib.callback.await('qbx_garages:server:getGarages', false) or {}
    local garage = garages and garages[garageName]
    local accessPoint = garage and garage.accessPoints and garage.accessPoints[1] or nil
    if not garage or not accessPoint or not accessPoint.coords then
        return nil, nil
    end

    return garage.label or garageName, accessPoint.coords
end

local function getTutorialObjectiveData(tutorial)
    if not tutorial or not tutorial.active then return nil end

    local currentStep = tostring(tutorial.currentStep or '')
    if currentStep == 'go_to_garage' or currentStep == 'retrieve_bike' then
        local garageLabel, coords = getTutorialGarageWaypoint(tutorial.assignedGarage or 'motelgarage')
        if not coords then return nil end

        return {
            coords = coords,
            title = garageLabel or 'garagem inicial',
            message = currentStep == 'go_to_garage'
                and ('Rota do tutorial atualizada: siga para %s e abra sua garagem.'):format(garageLabel or 'a garagem inicial')
                or ('Boa. Agora retire sua cruiser em %s para seguir o onboarding.'):format(garageLabel or 'a garagem inicial'),
        }
    end

    if currentStep == 'go_to_hub' or currentStep == 'accept_tutorial_contract' or currentStep == 'complete_first_delivery' then
        local hubId = tonumber(tutorial.assignedHubId)
        local hub = hubId and sharedConfig.hubs[hubId] or nil
        if not hub or not hub.coords then return nil end

        local message = 'Siga para o hub logístico designado para continuar seu primeiro serviço.'
        if currentStep == 'accept_tutorial_contract' then
            message = ('Perfeito. Você chegou ao hub %s. Abra os contratos e aceite a carga geral do tutorial.'):format(tutorial.assignedHubName or hub.name or 'inicial')
        elseif currentStep == 'complete_first_delivery' then
            message = 'Contrato tutorial ativo. Dirija com cuidado: colisões fortes reduzem a integridade da carga.'
        end

        return {
            coords = hub.coords,
            title = tutorial.assignedHubName or hub.name or 'hub inicial',
            message = message,
        }
    end

    return nil
end

local function applyTutorialGuidance(tutorial, shouldNotify)
    if not tutorial or not tutorial.active then
        tutorialGuidanceSignature = nil
        return
    end

    local signature = getTutorialGuidanceSignature(tutorial)
    if tutorialGuidanceSignature == signature then
        return
    end

    tutorialGuidanceSignature = signature
    local objective = getTutorialObjectiveData(tutorial)
    if not objective or not objective.coords then
        return
    end

    SetNewWaypoint(objective.coords.x, objective.coords.y)
    if shouldNotify and objective.message then
        notifyClient(objective.message, 'inform')
    end
end

local function setTutorialStateFromPayload(payload, shouldGuidePlayer)
    tutorialState = payload and payload.tutorial or nil
    applyTutorialGuidance(tutorialState, shouldGuidePlayer == true)
end

refreshTutorialStateFromServer = function(shouldGuidePlayer)
    local dashboardCallback = GetResourceState('cidade_tycoon_tablet') == 'started'
        and 'cidade_tycoon_tablet:server:getDashboard'
        or 'transport_tycoon_infinito:server:getTabletDashboard'
    local payload = lib.callback.await(dashboardCallback, false)
    if payload then
        setTutorialStateFromPayload(payload, shouldGuidePlayer == true)
    end

    return payload
end

RegisterNetEvent('cidade_tycoon_freelance:client:updateTutorialState', function(payload, shouldGuidePlayer)
    setTutorialStateFromPayload(payload, shouldGuidePlayer == true)
end)

RegisterNetEvent('transport_tycoon_infinito:client:updateTutorialState', function(payload, shouldGuidePlayer)
    TriggerEvent('cidade_tycoon_freelance:client:updateTutorialState', payload, shouldGuidePlayer)
end)

CreateThread(function()
    while true do
        local waitMilliseconds = 2000

        if tutorialState and tutorialState.active and tutorialState.currentStep == 'go_to_hub' then
            local hubId = tonumber(tutorialState.assignedHubId)
            local hub = hubId and sharedConfig.hubs[hubId] or nil
            if hub and hub.coords then
                waitMilliseconds = 1000
                local playerCoords = GetEntityCoords(PlayerPedId())
                local hubCoords = vector3(hub.coords.x, hub.coords.y, hub.coords.z)
                if #(playerCoords - hubCoords) <= 20.0 then
                    local response = lib.callback.await('cidade_tycoon_freelance:server:advanceTutorialStep', false, 'accept_tutorial_contract', {
                        assignedHubId = hubId,
                    })
                    if response and response.ok and response.tutorial then
                        tutorialState = response.tutorial
                        applyTutorialGuidance(tutorialState, true)
                        notifyClient('Boa. Agora aceite seu primeiro contrato no hub logístico.', 'success')
                    end
                    Wait(5000)
                end
            end
        end

        Wait(waitMilliseconds)
    end
end)

-- ==========================================================
-- CENTRO DE TREINAMENTO E DANOS DE CARGA (CLIENT-SIDE)
-- ==========================================================

local trainingPed = nil
local trainingBlip = nil

local function spawnTrainingInstructor()
    if trainingPed and DoesEntityExist(trainingPed) then return end

    local modelHash = joaat("s_m_m_dockwork_01")
    lib.requestModel(modelHash, 10000)

    local coords = vec4(1208.94, -2975.53, 5.87, 90.0)
    trainingPed = CreatePed(4, modelHash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)

    SetEntityAsMissionEntity(trainingPed, true, true)
    SetEntityInvincible(trainingPed, true)
    SetBlockingOfNonTemporaryEvents(trainingPed, true)
    FreezeEntityPosition(trainingPed, true)
    SetPedCanRagdoll(trainingPed, false)
    SetPedDiesWhenInjured(trainingPed, false)

    exports.ox_target:addLocalEntity(trainingPed, {
        {
            name = 'tycoon_open_training',
            icon = 'fa-solid fa-graduation-cap',
            label = 'Treinamento de Logística',
            distance = 2.2,
            onSelect = function()
                OpenTrainingPanel()
            end
        }
    })

    trainingBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(trainingBlip, 498)
    SetBlipScale(trainingBlip, 0.85)
    SetBlipColour(trainingBlip, 3)
    SetBlipAsShortRange(trainingBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Treinamento de Logística Tycoon")
    EndTextCommandSetBlipName(trainingBlip)

    SetModelAsNoLongerNeeded(modelHash)
end

function OpenTrainingPanel()
    local stats = lib.callback.await('cidade_tycoon_freelance:server:getDriverDashboard', false)
    if not stats then
        notifyClient('Não foi possível obter dados do motorista.', 'error')
        return
    end

    local options = {
        {
            title = 'Perfil do Motorista',
            description = ('Nível: %d | XP: %d/%d'):format(stats.driver_level, stats.experience, stats.driver_level * 1500),
            icon = 'user',
            disabled = true
        },
        {
            title = 'Treino de Carga Frágil',
            description = ('Nível atual: %d/5 | Requer Nível 3. Custo: $500'):format(stats.skill_fragile),
            icon = 'glass-water',
            disabled = stats.skill_fragile >= 5,
            onSelect = function()
                if stats.driver_level < 3 then
                    notifyClient('Você precisa de Nível de Motorista 3 para este treino.', 'error')
                    return
                end
                startTrainingSkillCheck('skill_fragile', 4, 1800, 'Cargas Frágeis')
            end
        },
        {
            title = 'Treino de Carga Valiosa',
            description = ('Nível atual: %d/5 | Requer Nível 6. Custo: $1.000'):format(stats.skill_heavy),
            icon = 'gem',
            disabled = stats.skill_heavy >= 5,
            onSelect = function()
                if stats.driver_level < 6 then
                    notifyClient('Você precisa de Nível de Motorista 6 para este treino.', 'error')
                    return
                end
                startTrainingSkillCheck('skill_heavy', 5, 1400, 'Cargas Valiosas')
            end
        },
        {
            title = 'Treino de Carga Perigosa',
            description = ('Nível atual: %d/5 | Requer Nível 10. Custo: $2.000'):format(stats.skill_hazardous),
            icon = 'biohazard',
            disabled = stats.skill_hazardous >= 5,
            onSelect = function()
                if stats.driver_level < 10 then
                    notifyClient('Você precisa de Nível de Motorista 10 para este treino.', 'error')
                    return
                end
                startTrainingSkillCheck('skill_hazardous', 6, 1100, 'Cargas Perigosas')
            end
        }
    }

    lib.registerContext({
        id = 'tycoon_training_panel',
        title = 'Centro de Treinamento Tycoon',
        options = options
    })
    lib.showContext('tycoon_training_panel')
end

function startTrainingSkillCheck(skillKey, speedCount, speedMs, skillName)
    notifyClient('Iniciando simulador de precisão...', 'inform')
    Wait(1000)

    local keys = {'e', 'e', 'e', 'e', 'e', 'e'}
    local success = lib.skillCheck(table.unpack(keys, 1, speedCount))

    if success then
        local res = lib.callback.await('cidade_tycoon_freelance:server:trainDriverSkill', false, skillKey)
        if res.ok then
            notifyClient(res.message, 'success')
            Wait(500)
            OpenTrainingPanel()
        else
            notifyClient(res.message, 'error')
        end
    else
        notifyClient('Você falhou no teste do simulador! Tente novamente.', 'error')
    end
end

-- Thread de danos à integridade da carga
local function getCargoProtectionMultiplier(contractType)
    local multiplier = (contractType == 'fragile') and 2.0 or 1.0
    
    -- Fetch protection from core skill
    local skillReduction = lib.callback.await('cidade_tycoon_freelance:server:getSkillModifier', false, 'fragile_cargo_protection') or 1.0
    
    return multiplier, skillReduction
end

local function calculateVehicleImpactCargoDamage(vehicle, lastVehicleHealth, lastVehicleSpeedKmh)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local currentVehHealth = (engineHealth + bodyHealth) / 2.0
    local currentSpeedKmh = GetEntitySpeed(vehicle) * 3.6
    local healthLoss = math.max(0.0, lastVehicleHealth - currentVehHealth)
    local speedDrop = math.max(0.0, lastVehicleSpeedKmh - currentSpeedKmh)
    local impactSpeed = math.max(lastVehicleSpeedKmh, currentSpeedKmh)

    if healthLoss < 3.0 and speedDrop < 10.0 then
        return 0, currentVehHealth, currentSpeedKmh, nil
    end

    if impactSpeed < 18.0 and healthLoss < 10.0 and speedDrop < 18.0 then
        return 0, currentVehHealth, currentSpeedKmh, nil
    end

    local impactScore = (healthLoss * 0.11) + (speedDrop * 0.24) + (math.max(0.0, impactSpeed - 20.0) * 0.16)
    if impactScore <= 0 then
        return 0, currentVehHealth, currentSpeedKmh, nil
    end

    local impactLabel = 'leve'
    if impactScore >= 20.0 then
        impactLabel = 'forte'
    elseif impactScore >= 10.0 then
        impactLabel = 'moderado'
    end

    return math.floor(impactScore), currentVehHealth, currentSpeedKmh, impactLabel
end

CreateThread(function()
    local lastVehicleHealth = 1000.0
    local lastVehicleSpeedKmh = 0.0
    local lastPlayerHealth = 100

    while true do
        local wait = 1000
        if ClientRuntimeState.activeMission and ClientRuntimeState.activeMission.loaded then
            wait = 250
            local playerPed = PlayerPedId()
            local vehicle = getMissionVehicleEntity()

            -- Monitora danos corporais no jogador
            local playerHealth = GetEntityHealth(playerPed)
            if playerHealth < lastPlayerHealth then
                local damage = lastPlayerHealth - playerHealth
                if damage > 2 then
                    local contractType = ClientRuntimeState.activeMission.contractType or 'comum'
                    local multiplier = (contractType == 'fragile') and 2.0 or 1.0
                    local cargoDamage = math.floor(damage * 0.4 * multiplier)
                    if cargoDamage > 0 then
                        ClientRuntimeState.activeMission.cargoHealth = math.max(0, ClientRuntimeState.activeMission.cargoHealth - cargoDamage)
                        updateFreelanceHUD()
                        notifyClient(('Sua carga sofreu danos corporais! Integridade: %d%%'):format(ClientRuntimeState.activeMission.cargoHealth), 'error')
                        if contractType == 'fragile' then playFragileImpactSound() end
                    end
                end
            end
            lastPlayerHealth = playerHealth

            -- Monitora danos fisicos no veiculo
            if vehicle ~= 0 and DoesEntityExist(vehicle) then
                ClientRuntimeState.lastVehicleSeenAt = GetGameTimer()
                local impactDamage, currentVehHealth, currentSpeedKmh, impactLabel = calculateVehicleImpactCargoDamage(vehicle, lastVehicleHealth, lastVehicleSpeedKmh)
                if impactDamage > 1 then -- Noise floor for integrity
                    local contractType = ClientRuntimeState.activeMission.contractType or 'comum'
                    local multiplier, skillReduction = getCargoProtectionMultiplier(contractType)
                    local cargoDamage = math.max(1, math.floor(impactDamage * multiplier * skillReduction))
                    ClientRuntimeState.activeMission.cargoHealth = math.max(0, ClientRuntimeState.activeMission.cargoHealth - cargoDamage)
                    updateFreelanceHUD()
                    
                    if cargoDamage >= 5 then -- Only notify significant damage
                        notifyClient(('Impacto %s! Carga danificada em %d%%. Integridade: %d%%'):format(
                            impactLabel or 'operacional',
                            cargoDamage,
                            ClientRuntimeState.activeMission.cargoHealth
                        ), 'error')
                        
                        if contractType == 'fragile' then playFragileImpactSound() end
                    end

                    -- Efeito Visual de Vazamento (Hazardous)
                    if contractType == 'hazardous' and ClientRuntimeState.activeMission.cargoHealth < 60 then
                        spawnHazardousEffect(vehicle)
                    end
                end
                lastVehicleHealth = currentVehHealth
                lastVehicleSpeedKmh = currentSpeedKmh
            else
                -- Timeout de veiculo perdido (60 segundos)
                local lastSeen = ClientRuntimeState.lastVehicleSeenAt or GetGameTimer()
                if GetGameTimer() - lastSeen > 60000 then
                    notifyClient('Missão cancelada: o veículo de entrega foi perdido ou destruído há muito tempo.', 'error')
                    TriggerServerEvent('cidade_tycoon_freelance:server:failFreelanceMission', 'Veiculo Perdido')
                    clearMissionState()
                end
                lastVehicleHealth = 1000.0
                lastVehicleSpeedKmh = 0.0
            end

            -- Se a integridade zerar, falha
            if ClientRuntimeState.activeMission.cargoHealth <= 0 then
                local contractType = ClientRuntimeState.activeMission.contractType or 'comum'
                if contractType == 'hazardous' and vehicle ~= 0 and DoesEntityExist(vehicle) then
                    local vCoords = GetEntityCoords(vehicle)
                    AddExplosion(vCoords.x, vCoords.y, vCoords.z, 2, 25.0, true, false, 1.0)
                end

                notifyClient('A mercadoria foi totalmente destruida devido ao excesso de danos no transporte!', 'error')
                TriggerServerEvent('cidade_tycoon_freelance:server:failFreelanceMission', 'Carga Destruida')
                cleanupCargoEffects(vehicle)
                clearMissionState()
            end
        else
            lastVehicleHealth = 1000.0
            lastVehicleSpeedKmh = 0.0
            lastPlayerHealth = 100
            wait = 1000
        end
        Wait(wait)
    end
end)

-- Thread periódica do HUD (atualiza distância, avisos e estado geral)
CreateThread(function()
    while true do
        if ClientRuntimeState.activeMission then
            pcall(updateFreelanceHUD)
            Wait(1000)
        else
            Wait(2000)
        end
    end
end)

-- Spawna o NPC na inicialização
CreateThread(function()
    Wait(3000)
    spawnTrainingInstructor()
end)

AddEventHandler('onResourceStop', function(stoppedResource)
    if stoppedResource ~= GetCurrentResourceName() then return end
    if trainingPed and DoesEntityExist(trainingPed) then
        DeleteEntity(trainingPed)
    end
    if trainingBlip and DoesBlipExist(trainingBlip) then
        RemoveBlip(trainingBlip)
    end
end)

function startPlayerBulkContractWithValidation(hubId, contractId)
    DebugLog("freelance", "startPlayerBulkContractWithValidation: Iniciando contrato corporativo %s na sede %s", tostring(contractId), tostring(hubId))
    local activePlate = lib.callback.await('cidade_tycoon_freelance:server:getActiveVehiclePlate', false)
    if not activePlate then
        notifyClient('Você não possui nenhum veículo ativo cadastrado na garagem!', 'error')
        return
    end

    local response = lib.callback.await('cidade_tycoon_freelance:server:startPlayerBulkContract', false, hubId, contractId)
    if not response or not response.ok or not response.mission then
        notifyClient(response and response.message or 'Não foi possível iniciar o contrato corporativo.', 'error')
        return
    end

    local mission = response.mission
    ClientRuntimeState.activeMission = {
        missionId = mission.missionId,
        mode = mission.mode,
        deliveryCoordinates = vector3(mission.deliveryCoordinates.x, mission.deliveryCoordinates.y, mission.deliveryCoordinates.z),
        deliveryRadius = mission.deliveryRadius,
        vehicleNetId = mission.vehicleNetId,
        vehicleModel = mission.vehicleModel,
        activePlate = activePlate,
        hubId = hubId,
        loaded = false,
        totalRequired = mission.totalRequired,
        capacity = mission.capacity,
        collectedFromOrigin = 0,
        inTrunk = 0,
        totalDelivered = 0,
        stops = mission.stops,
        currentStopIndex = 1,
        contractType = 'comum',
        cargoHealth = 100,
        carryingBox = false,
    }

    updateFreelanceHUD()
    notifyClient(('Contrato Corporativo iniciado! Usando veículo de placa %s (Capacidade: %d caixas). Pegue a carga no ponto de coleta.'):format(activePlate, mission.capacity), 'success')
    fetchCompanyContext()
end

exports('StartPlayerBulkContractWithValidation', startPlayerBulkContractWithValidation)

local function handleClearMission()
    clearMissionState()
    fetchCompanyContext()
end

RegisterNetEvent('cidade_tycoon_freelance:client:openTrainingPanel', OpenTrainingPanel)

RegisterNetEvent('transport_tycoon_infinito:client:clearMission', handleClearMission)
RegisterNetEvent('cidade_tycoon_freelance:client:clearMission', handleClearMission)
