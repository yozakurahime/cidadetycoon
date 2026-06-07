local logisticsConfig = require '@cidade_tycoon_logistics/config/shared'

local tabletOpen = false
local tabletProp = nil

local function notifyTablet(message, type)
    lib.notify({
        title = 'Tablet Tycoon',
        description = message,
        type = type or 'inform',
    })
end

local function forceCloseTabletUi()
    if not tabletOpen then return end
    
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeTablet' })
    
    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
    
    tabletOpen = false
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    StopAnimTask(ped, "amb@world_human_seat_wall_tablet@female@base", "base", 1.0)
    SetTimecycleModifier('default')
end

local function openTablet(startApp)
    if tabletOpen then
        if startApp then SendNUIMessage({ action = 'openTablet', startApp = startApp }) end
        return
    end

    -- Sound Effect: Tablet Startup
    PlaySoundFrontend(-1, "Event_Message_In", "GTAO_FM_Events_Soundset", 1)

    local res = lib.callback.await('cidade_tycoon_tablet:server:getDashboard', false)
    if not res then 
        notifyTablet('Falha ao sincronizar dados operacionais.', 'error')
        return 
    end

    local ped = PlayerPedId()
    
    -- Animation: Use tablet (allows movement with flag 49)
    lib.requestAnimDict("amb@world_human_seat_wall_tablet@female@base", 5000)
    TaskPlayAnim(ped, "amb@world_human_seat_wall_tablet@female@base", "base", 8.0, 1.0, -1, 49, 0, false, false, false)
    
    local model = joaat("prop_cs_tablet")
    if lib.requestModel(model, 5000) then
        local coords = GetEntityCoords(ped)
        tabletProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
        -- Attach to Left Hand (60309) with proper offsets for a tablet
        AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 60309), 0.03, 0.002, -0.02, 10.0, 160.0, 0.0, true, true, false, true, 1, true)
    end

    -- Visual: Tablet Focus Blur
    SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(1.5)

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openTablet', payload = res, startApp = startApp })
    tabletOpen = true
end

-- ==========================================
-- SAFE-EXIT MONITOR (Guardian Requirement)
-- ==========================================
CreateThread(function()
    while true do
        local wait = 1000
        if tabletOpen then
            wait = 250
            local ped = PlayerPedId()
            if IsEntityDead(ped) or IsPedRagdoll(ped) or IsPedInMeleeCombat(ped) then
                forceCloseTabletUi()
                notifyTablet('Conexão com o tablet perdida.', 'error')
            end
        end
        Wait(wait)
    end
end)

-- Callbacks & Events
RegisterNetEvent('cidade_tycoon_tablet:client:openTablet', openTablet)

RegisterNUICallback('closeTablet', function(_, cb)
    forceCloseTabletUi()
    cb({ ok = true })
end)

RegisterNUICallback('refreshDashboard', function(_, cb)
    local res = lib.callback.await('cidade_tycoon_tablet:server:getDashboard', false)
    cb({ ok = true, payload = res })
end)

RegisterNUICallback('tablet_mark_hub', function(data, cb)
    if not data or not data.hubId then return cb({ ok = false }) end
    local hubs = exports.cidade_tycoon_hubs:GetAllHubs()
    for _, hub in ipairs(hubs) do
        if hub.id == data.hubId then
            SetNewWaypoint(hub.coords.x, hub.coords.y)
            notifyTablet(('GPS definido para %s'):format(hub.name), 'success')
            return cb({ ok = true })
        end
    end
    cb({ ok = false })
end)

RegisterNUICallback('tablet_tutorial_waypoint', function(_, cb)
    local profile = LocalPlayer.state.tycoonProfile
    if not profile or not profile.tutorial or not profile.tutorial.active then
        return cb({ ok = false })
    end

    local step = profile.tutorial.currentStep
    if step == 'go_to_garage' or step == 'retrieve_bike' then
        SetNewWaypoint(275.58, -344.74) -- motelgarage coords
        notifyTablet('GPS definido para a Garagem Tycoon Inicial.', 'success')
        return cb({ ok = true })
    elseif step == 'go_to_hub' or step == 'accept_tutorial_contract' then
        SetNewWaypoint(1197.2, -3250.6) -- PostOP coords
        notifyTablet('GPS definido para o Hub Logístico (PostOP).', 'success')
        return cb({ ok = true })
    end

    cb({ ok = false })
end)

local function getClosestGarageAndAccessPoint(garages)
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local bestGarage, bestAccessIndex, bestDistance

    for garageName, garage in pairs(garages or {}) do
        if not garage.groups and garage.type ~= 'depot' then
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

RegisterNUICallback('tablet_pay_taxes', function(_, cb)
    local res = lib.callback.await('cidade_tycoon_core:server:payTaxes', false)
    cb(res)
end)

RegisterNUICallback('tablet_pay_financing', function(data, cb)
    local financingId = tonumber(data and data.financingId)
    if not financingId then return cb({ ok = false, message = 'Financiamento invalido.' }) end
    if GetResourceState('cidade_tycoon_market') ~= 'started' then
        return cb({ ok = false, message = 'Mercado financeiro indisponivel.' })
    end

    local res = lib.callback.await('cidade_tycoon_market:server:payInstallment', false, financingId)
    cb(res or { ok = false, message = 'Nao foi possivel pagar a parcela.' })
end)

RegisterNUICallback('purchaseCompany', function(data, cb)
    local warehouseId = tonumber(data and data.warehouseId)
    if not warehouseId then return cb({ ok = false, message = 'Galpao invalido.' }) end

    local res = lib.callback.await('cidade_tycoon_tablet:server:purchaseCompany', false, warehouseId)
    cb(res or { ok = false, message = 'Nao foi possivel criar a empresa.' })
end)

RegisterNUICallback('tablet_accept_job', function(data, cb)
    local jobId = tonumber(data and data.jobId)
    if not jobId then return cb({ ok = false, message = 'Contrato invalido.' }) end

    local res = lib.callback.await('cidade_tycoon_tablet:server:acceptJobBoardJob', false, jobId)
    if res and res.ok and res.origin then
        local coords = res.origin
        SetNewWaypoint(coords.x or coords[1] or 0.0, coords.y or coords[2] or 0.0)
    end
    cb(res or { ok = false, message = 'Nao foi possivel aceitar o contrato.' })
end)

RegisterNUICallback('cancelActiveJob', function(_, cb)
    cb({ ok = false, message = 'Cancelamento pelo tablet ainda nao esta disponivel.' })
end)

RegisterNUICallback('openTruckLogistics', function(_, cb)
    TriggerEvent('cidade_tycoon_trucklogistics:openViaTablet')
    cb({ ok = true })
end)

RegisterNUICallback('closeTruckLogistics', function(_, cb)
    TriggerEvent('cidade_tycoon_trucklogistics:closeViaTablet')
    cb({ ok = true })
end)

RegisterNetEvent('cidade_tycoon_tablet:client:truckLogisticsMessage', function(message)
    SendNUIMessage({
        action = 'truckLogisticsMessage',
        payload = message,
    })
end)

RegisterNetEvent('cidade_tycoon_tablet:client:forceCloseTablet', function()
    forceCloseTabletUi()
end)

RegisterNetEvent('cidade_tycoon_tablet:client:showToast', function(title, message, duration)
    SendNUIMessage({
        action = 'showToast',
        title = title,
        message = message,
        duration = duration or 3500
    })
end)

-- Sincronização de Relógio delegada nativamente ao JavaScript da interface CEF (app.js)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then forceCloseTabletUi() end
end)
