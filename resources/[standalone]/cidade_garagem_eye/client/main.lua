local VEHICLES = exports.qbx_core:GetVehiclesByName()
local GARAGE_PED_MODEL = `s_m_m_dockwork_01`

local blips = {}
local menus = {}
local spawnRequestToken = 0
local spawnCooldownUntil = 0

local activePeds = {}
local fallbackZones = {}
local exitTimers = {}
local garagePoints = {}

local VehicleState = {
    OUT = 0,
    GARAGED = 1,
    IMPOUNDED = 2,
}

local function notify(description, type)
    exports.qbx_core:Notify(description, type or 'primary')
end

local function getVehicleLabel(modelName)
    local data = VEHICLES[modelName]
    if not data then
        return modelName
    end

    if data.brand and data.brand ~= '' then
        return ('%s %s'):format(data.brand, data.name)
    end

    return data.name or modelName
end

local function formatPlateForDisplay(plate)
    plate = tostring(plate or ''):gsub('%s+', '')
    if #plate == 8 then
        return ('%s %s'):format(plate:sub(1, 4), plate:sub(5, 8))
    elseif #plate == 7 then
        return ('%s %s'):format(plate:sub(1, 3), plate:sub(4, 7))
    end
    return plate
end

local function getStateLabel(state)
    state = tonumber(state) or state

    if state == VehicleState.GARAGED then
        return '🟢 Na garagem'
    elseif state == VehicleState.OUT then
        return '🟡 Fora'
    elseif state == VehicleState.IMPOUNDED then
        return '🔴 Apreendido'
    end

    return '⚪ Desconhecido'
end

local function cleanAllLocalEntities()
    for i = 1, #blips do
        RemoveBlip(blips[i])
    end
    blips = {}

    for pointId, ped in pairs(activePeds) do
        if DoesEntityExist(ped) then
            exports.ox_target:removeLocalEntity(ped)
            DeletePed(ped)
        end
    end
    activePeds = {}

    for pointId, zoneId in pairs(fallbackZones) do
        exports.ox_target:removeZone(zoneId)
    end
    fallbackZones = {}

    exitTimers = {}
    menus = {}
end

local function rememberMenu(menuId)
    menus[#menus + 1] = menuId
end

local function clearMenus()
    for i = 1, #menus do
        pcall(lib.hideContext)
    end
    menus = {}
end

local function isSpawnCoolingDown()
    if spawnCooldownUntil == 0 then
        return false
    end

    if GetGameTimer() >= spawnCooldownUntil then
        spawnCooldownUntil = 0
        return false
    end

    return true
end

local function beginSpawnCooldown(timeoutMs)
    spawnRequestToken += 1
    local currentToken = spawnRequestToken
    spawnCooldownUntil = GetGameTimer() + timeoutMs

    CreateThread(function()
        Wait(timeoutMs)
        if spawnRequestToken == currentToken then
            spawnCooldownUntil = 0
        end
    end)
end

local function clearSpawnCooldown()
    spawnRequestToken += 1
    spawnCooldownUntil = 0
end

local function isSupportedGarage(garage)
    return garage and garage.vehicleType == 'car' and not garage.groups and garage.type ~= 'depot'
end

local function getGarages()
    return lib.callback.await('qbx_garages:server:getGarages', false) or {}
end

local function pushTutorialState(payload, shouldGuidePlayer)
    TriggerEvent('cidade_tycoon_freelance:client:updateTutorialState', payload, shouldGuidePlayer)
    if GetResourceState('cidade_tycoon_tablet') == 'started' then
        TriggerEvent('cidade_tycoon_tablet:client:updateTutorialState', payload, shouldGuidePlayer)
    end
end

local function getTutorialDashboardPayload()
    local callbackName = GetResourceState('cidade_tycoon_tablet') == 'started'
        and 'cidade_tycoon_tablet:server:getDashboard'
        or 'transport_tycoon_infinito:server:getTabletDashboard'
    return lib.callback.await(callbackName, false)
end

local function advanceTutorialStep(stepName, payload)
    local callbackName = GetResourceState('cidade_tycoon_tablet') == 'started'
        and 'cidade_tycoon_tablet:server:advanceTutorialStep'
        or 'transport_tycoon_infinito:server:advanceTutorialStep'
    return lib.callback.await(callbackName, false, stepName, payload)
end

local function findNearestGarageAccessPoint(maxDistance)
    local garages = getGarages()
    local playerPed = cache.ped or PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearestGarageName, nearestGarage, nearestAccessPointIndex, nearestDistance

    for garageName, garage in pairs(garages) do
        if isSupportedGarage(garage) then
            for accessPointIndex = 1, #(garage.accessPoints or {}) do
                local accessPoint = garage.accessPoints[accessPointIndex]
                local distance = #(playerCoords - accessPoint.coords.xyz)
                if (not maxDistance or distance <= maxDistance) and (not nearestDistance or distance < nearestDistance) then
                    nearestGarageName = garageName
                    nearestGarage = garage
                    nearestAccessPointIndex = accessPointIndex
                    nearestDistance = distance
                end
            end
        end
    end

    return nearestGarageName, nearestGarage, nearestAccessPointIndex, nearestDistance
end

local function spawnVehicle(vehicle, garageName, accessPointIndex)
    if isSpawnCoolingDown() then
        notify('Aguarde a retirada do veiculo atual.', 'error')
        return
    end

    if cache.vehicle then
        notify('Saia do veiculo antes de retirar outro.', 'error')
        return
    end

    clearMenus()
    beginSpawnCooldown(8000)
    notify('Solicitando retirada do veiculo...', 'inform')

    local success, payload = pcall(function()
        return lib.callback.await('cidade_garagem_eye:server:spawnVehicle', false, vehicle.id, garageName, accessPointIndex)
    end)

    clearSpawnCooldown()

    if not success then
        notify('Falha ao retirar o veiculo da garagem.', 'error')
        return
    end

    if not payload or not payload.ok then
        notify(payload and payload.message or 'Nao foi possivel retirar o veiculo agora.', 'error')
        return
    end

    if GetResourceState('cidade_tycoon_tablet') == 'started' then
        local tutorialPayload = getTutorialDashboardPayload()
        if tutorialPayload then
            pushTutorialState(tutorialPayload, true)
        end
    end

    notify(('Veiculo %s retirado com sucesso.'):format(getVehicleLabel(vehicle.modelName or vehicle.vehicle)), 'success')
end

local function parkCurrentVehicle(garageName)
    local vehicle = cache.vehicle
    if not vehicle or vehicle == 0 then
        notify('Entre em um veiculo para guardar nesta garagem.', 'error')
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local canPark = lib.callback.await('qbx_garages:server:isParkable', false, garageName, netId)
    if not canPark then
        notify('Esse veiculo nao pode ser guardado aqui.', 'error')
        return
    end

    lib.callback.await('qbx_garages:server:parkVehicle', false, netId, lib.getVehicleProperties(vehicle), garageName)
    notify('Veiculo guardado na garagem.', 'success')
end

local function getHealthIndicator(health)
    local val = tonumber(health) or 100
    if val >= 85 then return '🟢' end
    if val >= 50 then return '🟡' end
    if val >= 25 then return '🟠' end
    return '🔴'
end

local function openVehicleActions(vehicle, garageName, garageLabel, accessPointIndex)
    local menuId = ('cidade_garagem_eye_vehicle_%s_%s'):format(garageName, vehicle.id)
    local vehicleState = tonumber(vehicle.state) or vehicle.state
    local displayPlate = formatPlateForDisplay(vehicle.props and vehicle.props.plate or vehicle.plate)
    
    local tycoon = vehicle.tycoon or {}
    local maintenance = vehicle.maintenance or {}
    
    local options = {
        {
            title = getVehicleLabel(vehicle.modelName or vehicle.vehicle),
            description = ('Placa: %s | Tier %d'):format(displayPlate, tycoon.tier or 0),
            icon = 'car',
            readOnly = true,
        },
        {
            title = 'Especificações de Carga',
            description = ('Capacidade: %d caixas'):format(tycoon.capacity or 0),
            icon = 'box',
            readOnly = true,
        },
        {
            title = 'Estado Mecânico',
            description = ('Motor: %d%% | Freios: %d%% | Pneus: %d%%'):format(
                math.floor(maintenance.engine_health or 100),
                math.floor(maintenance.brakes_health or 100),
                math.floor(maintenance.tires_health or 100)
            ),
            icon = 'gears',
            readOnly = true,
            metadata = {
                { label = 'Km Rodados', value = ('%d km'):format(math.floor(maintenance.mileage or 0)) }
            }
        },
        {
            title = 'Status de Estacionamento',
            description = getStateLabel(vehicleState),
            icon = 'circle-info',
            readOnly = true,
        },
    }

    if vehicleState == VehicleState.OUT then
        options[#options + 1] = {
            title = 'Solicitar Reboque',
            description = 'Chamar o guincho para recolher este veiculo de volta para esta garagem.',
            icon = 'truck-pickup',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Solicitar Reboque',
                    content = ('Deseja solicitar o reboque do veiculo **%s** (Placa: %s) para esta garagem?\n\nO veiculo sera recolhido do mapa e devolvido a esta garagem.'):format(
                        getVehicleLabel(vehicle.modelName or vehicle.vehicle),
                        displayPlate
                    ),
                    centered = true,
                    cancel = true,
                    labels = {
                        confirm = 'Confirmar Reboque',
                        cancel = 'Cancelar',
                    },
                })

                if confirm ~= 'confirm' then
                    openVehicleActions(vehicle, garageName, garageLabel, accessPointIndex)
                    return
                end

                notify('Solicitando reboque...', 'inform')
                local response = lib.callback.await('cidade_garagem_eye:server:forceRecoverVehicle', false, vehicle.id, garageName)
                if response and response.ok then
                    notify(response.message, 'success')
                    local garages = getGarages()
                    local garage = garages[garageName]
                    if garage then
                        openGarageMenu(garageName, garage, accessPointIndex)
                    end
                else
                    notify(response and response.message or 'Falha ao solicitar o reboque.', 'error')
                end
            end
        }
    end

    options[#options + 1] = {
        title = 'Retirar veiculo',
        description = 'Enviar para a vaga de saida desta garagem.',
        icon = 'warehouse',
        onSelect = function()
            spawnVehicle(vehicle, garageName, accessPointIndex)
        end,
    }

    lib.registerContext({
        id = menuId,
        title = garageLabel,
        menu = ('cidade_garagem_eye_list_%s_%s'):format(garageName, accessPointIndex),
        options = options,
    })

    rememberMenu(menuId)
    lib.showContext(menuId)
end

local function openGarageMenu(garageName, garage, accessPointIndex)
    if GetResourceState('cidade_tycoon_tablet') == 'started' then
        local response = advanceTutorialStep('retrieve_bike', {
            assignedGarage = garageName,
        })
        if response and response.tutorial then
            pushTutorialState({ tutorial = response.tutorial }, true)
        end
        if response and response.ok and response.message then
            notify(response.message, 'inform')
        end
    end

    local vehicles = lib.callback.await('cidade_garagem_eye:server:getGarageVehicles', false, garageName)
    if not vehicles or not vehicles[1] then
        notify('Nenhum veiculo disponivel nesta garagem.', 'error')
        return
    end

    table.sort(vehicles, function(a, b)
        return getVehicleLabel(a.modelName or a.vehicle) < getVehicleLabel(b.modelName or b.vehicle)
    end)

    local menuId = ('cidade_garagem_eye_list_%s_%s'):format(garageName, accessPointIndex)
    local options = {}
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        vehicle.state = tonumber(vehicle.state) or vehicle.state
        local displayPlate = formatPlateForDisplay(vehicle.props and vehicle.props.plate or vehicle.plate)
        local health = vehicle.maintenance and vehicle.maintenance.engine_health or 100
        local tier = vehicle.tycoon and vehicle.tycoon.tier or 0

        options[#options + 1] = {
            title = getVehicleLabel(vehicle.modelName or vehicle.vehicle),
            description = ('%s | Tier %d | %s %d%%'):format(displayPlate, tier, getHealthIndicator(health), math.floor(health)),
            icon = 'car-side',
            arrow = true,
            onSelect = function()
                openVehicleActions(vehicle, garageName, garage.label, accessPointIndex)
            end,
        }
    end

    lib.registerContext({
        id = menuId,
        title = garage.label,
        options = options,
    })

    rememberMenu(menuId)
    lib.showContext(menuId)
end

local function registerGarageBlip(garage, accessPoint)
    local blipConfig = accessPoint.blip
    if not blipConfig then return end

    local blip = AddBlipForCoord(accessPoint.coords.x, accessPoint.coords.y, accessPoint.coords.z)
    SetBlipSprite(blip, blipConfig.sprite or 357)
    SetBlipColour(blip, blipConfig.color or 3)
    SetBlipScale(blip, 0.75)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blipConfig.name or garage.label or 'Garagem')
    EndTextCommandSetBlipName(blip)
    blips[#blips + 1] = blip
end

local function setupGaragePoints()
    -- Clean up first if needed
    for i = 1, #garagePoints do
        garagePoints[i]:remove()
    end
    garagePoints = {}

    local garages = getGarages()
    for garageName, garage in pairs(garages) do
        if isSupportedGarage(garage) then
            for accessPointIndex = 1, #(garage.accessPoints or {}) do
                local accessPoint = garage.accessPoints[accessPointIndex]
                
                -- Register Blip at startup
                registerGarageBlip(garage, accessPoint)

                local pointId = ('%s_%s'):format(garageName, accessPointIndex)

                local point = lib.points.new({
                    coords = accessPoint.coords.xyz,
                    distance = 25.0,
                    pointId = pointId,
                    garageName = garageName,
                    garage = garage,
                    accessPoint = accessPoint,
                    accessPointIndex = accessPointIndex
                })

                function point:onEnter()
                    -- Cancel pending exit timer
                    if exitTimers[self.pointId] then
                        exitTimers[self.pointId] = nil
                    end

                    -- If ped already exists, ignore
                    if activePeds[self.pointId] and DoesEntityExist(activePeds[self.pointId]) then
                        return
                    end

                    CreateThread(function()
                        local timeout = GetGameTimer() + 3000
                        RequestModel(GARAGE_PED_MODEL)
                        while not HasModelLoaded(GARAGE_PED_MODEL) do
                            Wait(50)
                            if GetGameTimer() > timeout then
                                break
                            end
                        end

                        if exitTimers[self.pointId] then
                            SetModelAsNoLongerNeeded(GARAGE_PED_MODEL)
                            return
                        end

                        if HasModelLoaded(GARAGE_PED_MODEL) then
                            local access = self.accessPoint
                            local ped = CreatePed(4, GARAGE_PED_MODEL, access.coords.x, access.coords.y, access.coords.z - 1.0, access.coords.w or 0.0, false, false)
                            if ped ~= 0 then
                                SetEntityInvincible(ped, true)
                                FreezeEntityPosition(ped, true)
                                SetBlockingOfNonTemporaryEvents(ped, true)
                                SetPedCanRagdoll(ped, false)
                                SetPedDiesWhenInjured(ped, false)
                                SetEntityAsMissionEntity(ped, true, true)

                                activePeds[self.pointId] = ped

                                exports.ox_target:addLocalEntity(ped, {
                                    {
                                        name = ('cidade_garagem_eye_open_%s'):format(self.pointId),
                                        icon = 'fa-solid fa-warehouse',
                                        label = ('Abrir %s'):format(self.garage.label),
                                        distance = 2.2,
                                        canInteract = function()
                                            return not cache.vehicle
                                        end,
                                        onSelect = function()
                                            openGarageMenu(self.garageName, self.garage, self.accessPointIndex)
                                        end,
                                    },
                                    {
                                        name = ('cidade_garagem_eye_store_%s'):format(self.pointId),
                                        icon = 'fa-solid fa-square-parking',
                                        label = ('Guardar em %s'):format(self.garage.label),
                                        distance = 2.8,
                                        canInteract = function()
                                            return cache.vehicle ~= false and cache.vehicle ~= nil
                                        end,
                                        onSelect = function()
                                            parkCurrentVehicle(self.garageName)
                                        end,
                                    }
                                })
                            end
                            SetModelAsNoLongerNeeded(GARAGE_PED_MODEL)
                        else
                            -- Fallback boxZone if model load failed
                            local access = self.accessPoint
                            local zoneId = exports.ox_target:addBoxZone({
                                coords = access.coords.xyz,
                                size = vec3(2.5, 2.5, 3.0),
                                rotation = access.coords.w or 0.0,
                                debug = false,
                                options = {
                                    {
                                        name = ('cidade_garagem_eye_fallback_open_%s'):format(self.pointId),
                                        icon = 'fa-solid fa-warehouse',
                                        label = ('Abrir %s (Painel)'):format(self.garage.label),
                                        canInteract = function()
                                            return not cache.vehicle
                                        end,
                                        onSelect = function()
                                            openGarageMenu(self.garageName, self.garage, self.accessPointIndex)
                                        end,
                                    },
                                    {
                                        name = ('cidade_garagem_eye_fallback_store_%s'):format(self.pointId),
                                        icon = 'fa-solid fa-square-parking',
                                        label = ('Guardar em %s (Painel)'):format(self.garage.label),
                                        canInteract = function()
                                            return cache.vehicle ~= false and cache.vehicle ~= nil
                                        end,
                                        onSelect = function()
                                            parkCurrentVehicle(self.garageName)
                                        end,
                                    }
                                }
                            })
                            fallbackZones[self.pointId] = zoneId
                        end
                    end)
                end

                function point:onExit()
                    local timerId = GetGameTimer() + 1500
                    exitTimers[self.pointId] = timerId

                    CreateThread(function()
                        Wait(1500)
                        if exitTimers[self.pointId] == timerId then
                            exitTimers[self.pointId] = nil

                            local ped = activePeds[self.pointId]
                            if ped and DoesEntityExist(ped) then
                                exports.ox_target:removeLocalEntity(ped)
                                DeletePed(ped)
                            end
                            activePeds[self.pointId] = nil

                            local zoneId = fallbackZones[self.pointId]
                            if zoneId then
                                exports.ox_target:removeZone(zoneId)
                            end
                            fallbackZones[self.pointId] = nil
                        end
                    end)
                end

                garagePoints[#garagePoints + 1] = point
            end
        end
    end
end

local function waitAndLoadGarages()
    CreateThread(function()
        local attempts = 0
        while attempts < 20 do
            attempts += 1
            if NetworkIsSessionStarted() and LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn then
                setupGaragePoints()
                return
            end
            Wait(1500)
        end

        setupGaragePoints()
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    waitAndLoadGarages()
end)

RegisterNetEvent('qbx_garages:client:garageRegistered', function()
    waitAndLoadGarages()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= cache.resource then return end
    waitAndLoadGarages()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    cleanAllLocalEntities()
end)

RegisterCommand('meusveiculos', function()
    local vehicles = lib.callback.await('cidade_garagem_eye:server:getPlayerVehicles', false)
    if not vehicles or not vehicles[1] then
        notify('Nenhum veiculo encontrado no seu cadastro.', 'error')
        return
    end

    local lines = {}
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local displayPlate = formatPlateForDisplay(vehicle.props and vehicle.props.plate or vehicle.plate)
        lines[#lines + 1] = ('%d. %s | %s | %s'):format(
            i,
            getVehicleLabel(vehicle.modelName or vehicle.vehicle),
            displayPlate ~= '' and displayPlate or '-',
            vehicle.garage or 'sem garagem'
        )
    end

    lib.alertDialog({
        header = 'Veiculos na Cidade',
        content = table.concat(lines, '\n'),
        centered = true,
        cancel = false
    })
end, false)

RegisterCommand('debuggaragem', function()
    local payload = lib.callback.await('cidade_garagem_eye:server:getPlayerVehiclesDebug', false)
    if not payload or not payload.vehicles or not payload.vehicles[1] then
        notify('Nenhum veiculo encontrado no registro persistido.', 'error')
        return
    end

    local lines = { ('CitizenID: %s'):format(payload.citizenid or 'desconhecido') }
    for i = 1, #payload.vehicles do
        local vehicle = payload.vehicles[i]
        lines[#lines + 1] = ('%d. id=%s | %s | placa=%s | garagem=%s | state=%s | tipo=%s'):format(
            i,
            tostring(vehicle.id or '-'),
            getVehicleLabel(vehicle.modelName),
            formatPlateForDisplay(vehicle.plate),
            vehicle.garage or '-',
            tostring(vehicle.state or '-'),
            vehicle.type or '-'
        )
    end

    lib.alertDialog({
        header = 'Debug Garagem',
        content = table.concat(lines, '\n'),
        centered = true,
        cancel = false
    })
end, false)

RegisterCommand('recuperarveiculos', function()
    local garageName = select(1, findNearestGarageAccessPoint(50.0)) or 'motelgarage'
    local response = lib.callback.await('cidade_garagem_eye:server:recoverOutVehicles', false, garageName)
    if not response then
        notify('Falha ao recuperar os veiculos.', 'error')
        return
    end

    notify(response.message, response.ok and 'success' or 'error')
end, false)

RegisterCommand('garagem_reload', function()
    waitAndLoadGarages()
    notify('Recarregando NPCs e blips das garagens.', 'inform')
end, false)

RegisterCommand('testespawn', function()
    local garageName, garage, accessPointIndex = findNearestGarageAccessPoint(20.0)
    if not garageName or not garage or not accessPointIndex then
        notify('Nenhuma garagem proxima foi encontrada para teste.', 'error')
        return
    end

    local vehicles = lib.callback.await('cidade_garagem_eye:server:getGarageVehicles', false, garageName)
    if not vehicles or not vehicles[1] then
        notify(('Nenhum veiculo disponivel em %s para teste.'):format(garage.label or garageName), 'error')
        return
    end

    spawnVehicle(vehicles[1], garageName, accessPointIndex)
end, false)
