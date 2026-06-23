-- client/ev_charging.lua
-- EV charging UI - activates when an EV is at a fuel station

local isCharging = false
local chargeThread = nil
local stopCharging

local function notify(msg, type)
    lib.notify({ title = 'Carregador EV', description = msg, type = type or 'inform' })
end

local function startCharging(vehicle, plate)
    if isCharging then
        notify('Ja esta carregando.', 'error')
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local res = lib.callback.await('cidade_tycoon_maintenance:server:startCharging', false, netId)
    if not res or not res.ok then
        notify(res and res.message or 'Erro ao iniciar carga.', 'error')
        return
    end

    isCharging = true

    -- Show charging UI
    lib.showTextUI('Carregando... Pressione X para parar', {
        position = 'right-center',
        icon = 'bolt',
    })

    chargeThread = CreateThread(function()
        local currentCharge = res.currentCharge or 0

        while isCharging do
            Wait(1000)

            -- Check proximity
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            if #(coords - GetEntityCoords(vehicle)) > 8.0 then
                stopCharging()
                notify('Carregamento interrompido: muito distante do veiculo.', 'error')
                break
            end

            -- Send charging tick
            local tickRes = lib.callback.await('cidade_tycoon_maintenance:server:chargingTick', false)
            if not tickRes then
                stopCharging()
                notify('Erro na comunicacao com o servidor.', 'error')
                break
            end

            if tickRes.chargeStopped then
                stopCharging()
                notify(tickRes.message or 'Carregamento interrompido.', 'error')
                break
            end

            currentCharge = tickRes.charge
            local chargeText = ('Carregando: %.0f%%'):format(currentCharge)
            lib.showTextUI(chargeText .. ' | Pressione X para parar', {
                position = 'right-center',
                icon = 'bolt',
            })

            if tickRes.isFull then
                stopCharging()
                notify('Bateria totalmente carregada! ($' .. (tickRes.costThisTick or 0) .. ')', 'success')
                PlaySoundFrontend(-1, "PURCHASE_ACK", "HUD_LIQUIPEDIA_SOUNDSET", 1)
                break
            end

            -- Check for stop key (X = 73)
            if IsControlJustPressed(0, 73) then
                stopCharging()
                notify('Carregamento interrompido pelo jogador.', 'inform')
                break
            end
        end
    end)
end

stopCharging = function()
    isCharging = false
    if chargeThread then
        chargeThread = nil
    end
    lib.hideTextUI()
    lib.callback.await('cidade_tycoon_maintenance:server:stopCharging', false)
end

-- Monitor thread: detect when in an EV at a charging station
local CHARGING_STATIONS = {
    vector3(49.4187, 2778.793, 58.043),
    vector3(1039.958, 2671.134, 39.550),
    vector3(1207.260, 2660.175, 37.899),
    vector3(2539.685, 2594.192, 37.944),
    vector3(265.648, -1261.309, 29.292),
    vector3(819.653, -1028.846, 26.403),
    vector3(1181.381, -330.847, 69.316),
    vector3(-70.2148, -1761.792, 29.534),
    vector3(-526.019, -1211.003, 18.184),
    vector3(-724.619, -935.1631, 19.213),
    vector3(620.72, 268.86, 103.09),
    vector3(179.75, 6602.73, 31.87),
    vector3(2004.99, 3775.09, 32.4),
    vector3(-2555.35, 2334.6, 33.08),
}

local function isNearCharger(coords)
    for _, station in ipairs(CHARGING_STATIONS) do
        if #(coords - station) < 25.0 then return true end
    end
    return false
end

CreateThread(function()
    local showingUI = false
    while true do
        Wait(250)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            local isEV = exports.cidade_tycoon_core:IsVehicleElectric(GetEntityModel(vehicle))
            if isEV and not isCharging then
                local coords = GetEntityCoords(ped)
                local nearStation = isNearCharger(coords)
                local plate = GetVehicleNumberPlateText(vehicle)

                if nearStation and plate then
                    if not showingUI then
                        lib.showTextUI('[E] Carregar Bateria', { position = 'right-center', icon = 'bolt' })
                        showingUI = true
                    end
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        showingUI = false
                        startCharging(vehicle, plate)
                    end
                elseif showingUI then
                    lib.hideTextUI()
                    showingUI = false
                end
            elseif showingUI then
                lib.hideTextUI()
                showingUI = false
            end
        elseif showingUI then
            lib.hideTextUI()
            showingUI = false
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isCharging then
        stopCharging()
    end
end)
