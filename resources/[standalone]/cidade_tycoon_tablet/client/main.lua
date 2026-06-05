local sharedConfig = require 'config.shared'

local tabletOpen = false
local tabletProp = nil
local tutorialPromptQueued = false
local tutorialState = nil
local tutorialGuidanceSignature = nil

local function notifyTablet(message, notificationType)
    if GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:Notify(message, notificationType or 'inform')
        return
    end

    TriggerEvent('QBCore:Notify', message, notificationType or 'primary')
end

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
    local ok, garages = pcall(function()
        return lib.callback.await('qbx_garages:server:getGarages', 1500)
    end)
    garages = ok and garages or {}
    
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

        local message = 'Siga para o hub logistico designado para continuar seu primeiro servico.'
        if currentStep == 'accept_tutorial_contract' then
            message = ('Perfeito. Voce chegou ao hub %s. Abra os contratos e aceite a carga geral do tutorial.'):format(tutorial.assignedHubName or hub.name or 'inicial')
        elseif currentStep == 'complete_first_delivery' then
            message = 'Contrato tutorial ativo. Dirija com cuidado: colisoes fortes reduzem a integridade da carga.'
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
        notifyTablet(objective.message, 'inform')
    end
end

local function setTutorialStateFromPayload(payload, shouldGuidePlayer)
    tutorialState = payload and payload.tutorial or nil
    applyTutorialGuidance(tutorialState, shouldGuidePlayer == true)
end

local function forceCloseTabletUi()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeTablet' })
    tabletOpen = false

    local playerPed = PlayerPedId()
    if playerPed and playerPed ~= 0 then
        ClearPedTasks(playerPed)
    end

    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
end

local function normalizePlate(plate)
    return exports.cidade_tycoon_core:NormalizePlate(plate)
end

local function findVehFromPlateAndLocate(plate)
    local gameVehicles = GetGamePool('CVehicle')
    local plateNormalized = normalizePlate(plate)
    for i = 1, #gameVehicles do
        local vehicle = gameVehicles[i]
        if DoesEntityExist(vehicle) and normalizePlate(GetVehicleNumberPlateText(vehicle)) == plateNormalized then
            local vehCoords = GetEntityCoords(vehicle)
            SetNewWaypoint(vehCoords.x, vehCoords.y)
            return true
        end
    end
    return false
end

local function getClosestGarageAndAccessPoint(garages)
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local bestGarage, bestAccessIndex, bestDistance

    for garageName, garage in pairs(garages or {}) do
        if not garage.groups and not garage.type then
            for idx = 1, #(garage.accessPoints or {}) do
                local access = garage.accessPoints[idx]
                local dist = #(pcoords - access.coords.xyz)
                if not bestDistance or dist < bestDistance then
                    bestDistance = dist
                    bestGarage = garageName
                    bestAccessIndex = idx
                end
            end
        end
    end

    return bestGarage, bestAccessIndex, bestDistance or 99999.0
end

local function getTabletAppsPayload()
    local payload = nil
    print('[cidade_tycoon_tablet] Client: Solicitando dashboard ao servidor...')
    local ok, err = pcall(function()
        payload = lib.callback.await('cidade_tycoon_tablet:server:getDashboard', 5000)
    end)
    
    if not ok then
        print('[cidade_tycoon_tablet] Client: Erro na callback do servidor: ' .. tostring(err))
    end

    payload = (ok and payload) or {}
    
    payload.garage = payload.garage or { vehicles = {}, garages = {} }
    payload.city = payload.city or { announcements = {}, services = {}, richest = {}, tycoonTop = {} }

    if GetResourceState('npwd_qbx_garages_plus') == 'started' then
        pcall(function()
            local garageDashboard = lib.callback.await('npwd_qbx_garages_plus:server:getDashboard', 2000)
            if garageDashboard and garageDashboard.ok and garageDashboard.data then
                payload.garage = garageDashboard.data
            end
        end)
    end

    if GetResourceState('npwd_qbx_city') == 'started' then
        pcall(function()
            local feed = lib.callback.await('npwd_qbx_city:server:getCityFeed', 2000)
            if feed and feed.ok and feed.data then
                payload.city.announcements = feed.data.announcements or {}
                payload.city.services = feed.data.services or {}
            end
        end)
    end

    pcall(function()
        payload.city.richest = lib.callback.await('transport_tycoon_infinito:server:getRichestPlayersLeaderboard', 2000, 10) or {}
    end)
    pcall(function()
        payload.city.tycoonTop = lib.callback.await('transport_tycoon_infinito:server:getStatueLeaderboardTop10', 2000) or {}
    end)
    
    setTutorialStateFromPayload(payload, false)

    print(('[cidade_tycoon_tablet] Client: Dashboard carregado. Veiculos na garagem: %s'):format(tostring(payload.garage and payload.garage.vehicles and #payload.garage.vehicles or 0)))

    return payload
end

local function openTablet()
    if tabletOpen then return end
    print('[cidade_tycoon_tablet] Client: Executando openTablet...')

    local data = getTabletAppsPayload()
    if data and data.tutorial and data.tutorial.active and data.tutorial.currentStep == 'welcome' then
        pcall(function()
            local response = lib.callback.await('cidade_tycoon_tablet:server:advanceTutorialStep', 2000, 'go_to_garage', {})
            if response and response.ok and response.tutorial then
                data.tutorial = response.tutorial
                setTutorialStateFromPayload(data, false)
            end
        end)
    end
    if not data then
        notifyTablet('Nao foi possivel carregar os dados do tablet.', 'error')
        return
    end

    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
        pcall(function()
            local animDict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base'
            local animName = 'base'
            RequestAnimDict(animDict)
            local timeout = GetGameTimer() + 2000
            while not HasAnimDictLoaded(animDict) and GetGameTimer() < timeout do
                Wait(10)
            end
            if HasAnimDictLoaded(animDict) then
                TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)

                local modelHash = joaat('prop_cs_tablet')
                RequestModel(modelHash)
                local modelTimeout = GetGameTimer() + 2000
                while not HasModelLoaded(modelHash) and GetGameTimer() < modelTimeout do
                    Wait(10)
                end
                if HasModelLoaded(modelHash) then
                    local coords = GetEntityCoords(playerPed)
                    tabletProp = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, true)
                    local boneIdx = GetPedBoneIndex(playerPed, 60309)
                    AttachEntityToEntity(tabletProp, playerPed, boneIdx, 0.03, 0.002, -0.02, 10.0, 160.0, 0.0, true, true, false, true, 1, true)
                    SetModelAsNoLongerNeeded(modelHash)
                end
            end
        end)
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openTablet',
        payload = data
    })
    tabletOpen = true
    setTutorialStateFromPayload(data, true)
end

RegisterNetEvent('cidade_tycoon_tablet:client:useTabletItem', function(_, slotData)
    exports.ox_inventory:useItem(slotData, function(usedItem)
        if usedItem then
            openTablet()
        end
    end)
end)

RegisterNetEvent('transport_tycoon_infinito:client:useTabletItem', function(...)
    TriggerEvent('cidade_tycoon_tablet:client:useTabletItem', ...)
end)

RegisterNetEvent('cidade_tycoon_tablet:client:openTablet', openTablet)
RegisterNetEvent('transport_tycoon_infinito:client:openTablet', openTablet)

RegisterNetEvent('cidade_tycoon_tablet:client:queueTutorialPrompt', function()
    if tutorialPromptQueued then return end
    tutorialPromptQueued = true

    CreateThread(function()
        Wait(1500)

        for _ = 1, 20 do
            if not LocalPlayer.state.isLoggedIn then
                break
            end

            if not tabletOpen and not IsPauseMenuActive() and not IsEntityDead(PlayerPedId()) then
                notifyTablet('Seu tablet recebeu um guia inicial da operacao. Vamos comecar por ele.', 'inform')
                openTablet()
                break
            end

            Wait(1000)
        end

        tutorialPromptQueued = false
    end)
end)

RegisterNetEvent('transport_tycoon_infinito:client:queueTutorialPrompt', function()
    TriggerEvent('cidade_tycoon_tablet:client:queueTutorialPrompt')
end)

RegisterNetEvent('cidade_tycoon_tablet:client:updateTutorialState', function(payload, shouldGuidePlayer)
    setTutorialStateFromPayload(payload, shouldGuidePlayer == true)
end)

RegisterNetEvent('transport_tycoon_infinito:client:updateTutorialState', function(payload, shouldGuidePlayer)
    TriggerEvent('cidade_tycoon_tablet:client:updateTutorialState', payload, shouldGuidePlayer)
end)
RegisterNetEvent('cidade_tycoon_tablet:client:updateFreelanceHUD', function(data)
    SendNUIMessage({
        action = 'updateFreelanceHUD',
        payload = data
    })
end)

RegisterNetEvent('cidade_tycoon_tablet:client:hideFreelanceHUD', function()
    SendNUIMessage({
        action = 'hideFreelanceHUD'
    })
end)

RegisterNetEvent('cidade_tycoon_tablet:client:setWaypoint', function(coords)
    if not coords then return end
    SetNewWaypoint(coords.x, coords.y)
    notifyTablet('Rota marcada no GPS.', 'success')
end)

RegisterNUICallback('purchaseCompany', function(data, cb)
    if not data or not data.warehouseId then return cb({ ok = false }) end
    local result = lib.callback.await('cidade_tycoon_logistics:server:purchaseCompany', false, data.warehouseId)
    cb(result)
end)

RegisterNUICallback('recruitEmployee', function(data, cb)
    if not data or not data.level then return cb({ ok = false }) end
    local result = lib.callback.await('cidade_tycoon_logistics:server:recruitEmployee', false, data.level)
    cb(result)
end)

RegisterNUICallback('startNPCDelivery', function(data, cb)
    if not data or not data.employeeId or not data.plate then return cb({ ok = false }) end
    local result = lib.callback.await('cidade_tycoon_logistics:server:startNPCDelivery', false, data.employeeId, data.plate, data.routeType or 'land')
    cb(result)
end)

RegisterNUICallback('startProduction', function(data, cb)
    if not data or not data.recipeKey then return cb({ ok = false }) end
    local result = lib.callback.await('cidade_tycoon_production:server:startProduction', false, data.recipeKey)
    cb(result)
end)

RegisterNUICallback('closeTablet', function(_, cb)
    forceCloseTabletUi()
    cb({ ok = true })
end)

RegisterNUICallback('tablet_mark_hub', function(data, cb)
    if not data or not data.hubId then return cb({ ok = false }) end
    
    local hubs = exports.cidade_tycoon_hubs:GetAllHubs()
    local targetHub = nil
    for _, hub in ipairs(hubs) do
        if hub.id == data.hubId then
            targetHub = hub
            break
        end
    end

    if targetHub then
        SetNewWaypoint(targetHub.coords.x, targetHub.coords.y)
        notifyTablet(('GPS definido para %s'):format(targetHub.name), 'success')
        cb({ ok = true })
    else
        cb({ ok = false, message = 'Hub nao encontrado.' })
    end
end)

RegisterNUICallback('tablet_pay_financing', function(data, cb)
    if not data or not data.financingId then return cb({ ok = false }) end
    
    local result = lib.callback.await('cidade_tycoon_market:server:payInstallment', false, data.financingId)
    cb(result)
end)

RegisterNUICallback('tablet_accept_job', function(data, cb)
    if not data or not data.jobId then return cb({ ok = false }) end
    local result = lib.callback.await('cidade_tycoon_tablet:server:tablet_accept_job', 2500, data.jobId)
    cb(result)
end)

RegisterNUICallback('cancelActiveJob', function(_, cb)
    local success, message = false, 'Servico indisponivel.'
    pcall(function()
        success, message = lib.callback.await('cidade_tycoon_tablet:server:cancelFreelanceWithFine', 2500)
    end)
    
    if message then
        notifyTablet(message, success and 'success' or 'error')
    end

    if success then
        TriggerEvent('cidade_tycoon_freelance:client:clearMission')
        local data = getTabletAppsPayload()
        setTutorialStateFromPayload(data, false)
        cb({ ok = true, payload = data })
    else
        cb({ ok = false, message = message })
    end
end)

RegisterNUICallback('tablet_pay_installment', function(data, cb)
    local response = nil
    pcall(function()
        response = lib.callback.await('transport_tycoon_infinito:server:payVehicleInstallment', 2500, data.vehicleId)
    end)
    
    if response and response.message then
        notifyTablet(response.message, response.ok and 'success' or 'error')
    end

    local payload = getTabletAppsPayload()
    setTutorialStateFromPayload(payload, false)
    cb({ ok = response and response.ok or false, payload = payload })
end)

RegisterNUICallback('tablet_buyout_vehicle', function(data, cb)
    local response = nil
    pcall(function()
        response = lib.callback.await('transport_tycoon_infinito:server:buyoutVehicleContract', 2500, data.vehicleId)
    end)
    
    if response and response.message then
        notifyTablet(response.message, response.ok and 'success' or 'error')
    end

    local payload = getTabletAppsPayload()
    setTutorialStateFromPayload(payload, false)
    cb({ ok = response and response.ok or false, payload = payload })
end)

RegisterNUICallback('tablet_renew_rental', function(data, cb)
    local response = nil
    pcall(function()
        response = lib.callback.await('transport_tycoon_infinito:server:renewVehicleRental', 2500, data.vehicleId)
    end)
    
    if response and response.message then
        notifyTablet(response.message, response.ok and 'success' or 'error')
    end

    local payload = getTabletAppsPayload()
    setTutorialStateFromPayload(payload, false)
    cb({ ok = response and response.ok or false, payload = payload })
end)

RegisterNUICallback('tablet_pay_operational_debt', function(data, cb)
    local response = nil
    pcall(function()
        response = lib.callback.await('cidade_tycoon_maintenance:server:payOperationalDebt', 3000, data.vehicleId)
    end)
    
    if response and response.message then
        notifyTablet(response.message, response.ok and 'success' or 'error')
    end

    local payload = getTabletAppsPayload()
    setTutorialStateFromPayload(payload, false)
    cb({ ok = response and response.ok or false, payload = payload })
end)

RegisterNUICallback('refreshDashboard', function(_, cb)
    local payload = getTabletAppsPayload()
    cb({ ok = true, payload = payload })
end)

RegisterNUICallback('tablet_set_waypoint', function(data, cb)
    cb({ ok = findVehFromPlateAndLocate(data and data.plate) })
end)

RegisterNUICallback('tablet_tutorial_waypoint', function(_, cb)
    local objective = getTutorialObjectiveData(tutorialState)
    if not objective or not objective.coords then
        cb({ ok = false, message = 'Nenhum objetivo guiado ativo no momento.' })
        return
    end

    SetNewWaypoint(objective.coords.x, objective.coords.y)
    notifyTablet(('Rota definida para %s.'):format(objective.title or 'o proximo passo do tutorial'), 'inform')
    cb({ ok = true })
end)

RegisterNUICallback('tablet_spawn_vehicle', function(data, cb)
    local vehicleId = tonumber(data and data.vehicleId)
    if not vehicleId or GetResourceState('cidade_garagem_eye') ~= 'started' then
        cb({ ok = false, message = 'O sistema de garagens nao esta disponivel.' })
        return
    end

    local ok, garages = pcall(function()
        return lib.callback.await('qbx_garages:server:getGarages', 2000)
    end)
    if not ok or not garages then
        cb({ ok = false, message = 'As garagens nao puderam ser carregadas.' })
        return
    end

    local garageName, accessPointIndex, distance = getClosestGarageAndAccessPoint(garages)
    if not garageName or not accessPointIndex or distance > 12.0 then
        cb({ ok = false, message = 'Chegue mais perto de uma garagem para retirar o veiculo.' })
        return
    end

    local response = nil
    pcall(function()
        response = lib.callback.await('cidade_garagem_eye:server:spawnVehicleFromTablet', 3000, vehicleId, garageName, accessPointIndex)
    end)
    
    if not response or not response.ok then
        cb({ ok = false, message = response and response.message or 'Nao foi possivel retirar o veiculo.' })
        return
    end

    cb({ ok = true, netId = response.netId, plate = response.plate })
end)

-- Thread de Sincronizacao do Relogio do Jogo para o NUI
CreateThread(function()
    while true do
        if tabletOpen then
            local hours = GetClockHours()
            local minutes = GetClockMinutes()
            SendNUIMessage({
                action = 'updateTime',
                time = string.format("%02d:%02d", hours, minutes)
            })
            Wait(2000)
        else
            Wait(1000)
        end
    end
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
                local hubCoords = vec3(hub.coords.x, hub.coords.y, hub.coords.z)
                if #(playerCoords - hubCoords) <= 20.0 then
                    pcall(function()
                        local response = lib.callback.await('cidade_tycoon_tablet:server:advanceTutorialStep', 2000, 'accept_tutorial_contract', {
                            assignedHubId = hubId,
                        })
                        if response and response.ok and response.tutorial then
                            tutorialState = response.tutorial
                            applyTutorialGuidance(tutorialState, true)
                            notifyTablet('Boa. Agora aceite seu primeiro contrato no hub logistico.', 'success')
                        end
                    end)
                    Wait(5000)
                end
            end
        end

        Wait(waitMilliseconds)
    end
end)

AddEventHandler('onResourceStop', function(stoppedResource)
    if stoppedResource ~= GetCurrentResourceName() then return end
    forceCloseTabletUi()
end)

AddEventHandler('onClientResourceStart', function(startedResource)
    if startedResource ~= GetCurrentResourceName() then return end
    Wait(250)
    forceCloseTabletUi()
end)
