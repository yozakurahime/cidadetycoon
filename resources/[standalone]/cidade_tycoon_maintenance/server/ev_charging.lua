-- server/ev_charging.lua
-- Electric vehicle charging system integrated with bazufix fuel stations

local CHARGING_PRICE_PER_PERCENT = 7 -- $ per % of charge
local CHARGE_SPEED_PER_SECOND = 2.0 -- % per second
local activeCharging = {} -- [source] = { plate, vehicleNetId, timer }
local function normalizePlate(plate)
    return exports.cidade_tycoon_core:NormalizePlate(plate)
end

local function getVehicleRowByPlate(plate)
    local normalizedPlate = normalizePlate(plate)
    return MySQL.single.await([[
        SELECT plate, vehicle
        FROM player_vehicles
        WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
        LIMIT 1
    ]], { plate, normalizedPlate })
end

-- Bazufix station locations (same as bazufix-fuel config)
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
        if #(coords - station) < 20.0 then
            return true
        end
    end
    return false
end

local function isVehicleElectric(plate)
    local row = getVehicleRowByPlate(plate)
    if row then
        return exports.cidade_tycoon_core:IsVehicleElectric(row.vehicle)
    end
    return false
end

--- Start charging an EV
lib.callback.register('cidade_tycoon_maintenance:server:startCharging', function(source, vehicleNetId)
    if activeCharging[source] then
        return { ok = false, message = 'Ja esta carregando um veiculo.' }
    end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    if not isNearCharger(coords) then
        return { ok = false, message = 'Voce precisa estar em um posto de combustivel.' }
    end

    local entity = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not entity or entity == 0 then
        return { ok = false, message = 'Veiculo nao encontrado.' }
    end

    local plate = normalizePlate(GetVehicleNumberPlateText(entity))
    if not plate or plate == '' then
        return { ok = false, message = 'Placa invalida.' }
    end

    if not isVehicleElectric(plate) then
        return { ok = false, message = 'Este veiculo nao e eletrico.' }
    end

    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then
        return { ok = false, message = 'Veiculo nao registrado.' }
    end

    -- Default battery_charge if not set (backward compatibility)
    local currentCharge = status.battery_charge
    if currentCharge == nil then
        -- Check if this is an existing vehicle without battery_charge column
        -- It will get the default after DB migration
        local row = MySQL.single.await('SELECT battery_charge FROM tycoon_vehicle_status WHERE plate = ?', { normalizePlate(plate) })
        currentCharge = row and row.battery_charge ~= nil and row.battery_charge or 100.0
    end

    if currentCharge >= 100.0 then
        return { ok = false, message = 'Bateria ja esta totalmente carregada.' }
    end

    local owner = exports.cidade_tycoon_core:GetCitizenId(source)
    if not owner then
        return { ok = false, message = 'Erro ao identificar jogador.' }
    end

    activeCharging[source] = {
        plate = plate,
        vehicleNetId = vehicleNetId,
        startCharge = currentCharge,
    }

    return { ok = true, message = 'Carregando...', currentCharge = currentCharge }
end)

--- Process charging tick (called from client every second)
lib.callback.register('cidade_tycoon_maintenance:server:chargingTick', function(source)
    local session = activeCharging[source]
    if not session then
        return { ok = false, message = 'Sessao de carga nao encontrada.' }
    end

    local status = exports.cidade_tycoon_core:GetVehicleStatus(session.plate)
    if not status then
        activeCharging[source] = nil
        return { ok = false, message = 'Erro ao ler status do veiculo.' }
    end

    -- Charge calculation
    local chargeAmount = CHARGE_SPEED_PER_SECOND
    local currentCharge = status.battery_charge or 0.0
    local newCharge = math.min(100.0, currentCharge + chargeAmount)
    local chargedThisTick = newCharge - currentCharge

    -- Calculate cost
    local cost = math.floor(chargedThisTick * CHARGING_PRICE_PER_PERCENT)

    -- Deduct money from player
    if cost > 0 then
        local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
        if player then
            local balance = exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank')
            if balance < cost then
                activeCharging[source] = nil
                return { ok = false, message = 'Saldo insuficiente no banco.', chargeStopped = true }
            end
            if not exports.cidade_tycoon_core:RemoveMoney(player, 'bank', cost, 'ev-charging') then
                activeCharging[source] = nil
                return { ok = false, message = 'Falha no pagamento.', chargeStopped = true }
            end
        end
    end

    -- Update status
    status.battery_charge = newCharge
    exports.cidade_tycoon_core:UpdateVehicleStatus(session.plate, status)

    -- Sync state bag
    if exports.cidade_tycoon_maintenance and exports.cidade_tycoon_maintenance.SyncVehicleStateBag then
        exports.cidade_tycoon_maintenance:SyncVehicleStateBag(session.plate, status)
    end

    local isFull = newCharge >= 100.0
    if isFull then
        activeCharging[source] = nil
    end

    return {
        ok = true,
        charge = newCharge,
        isFull = isFull,
        costThisTick = cost,
        totalCost = 0, -- we could track total if needed
    }
end)

--- Stop charging
lib.callback.register('cidade_tycoon_maintenance:server:stopCharging', function(source)
    if activeCharging[source] then
        activeCharging[source] = nil
        return { ok = true, message = 'Carregamento interrompido.' }
    end
    return { ok = false, message = 'Nenhuma sessao ativa.' }
end)

--- Get battery charge for HUD
exports('GetBatteryCharge', function(plate)
    plate = normalizePlate(plate)
    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if status then
        return status.battery_charge or 0.0
    end
    return 0.0
end)

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    activeCharging[source] = nil
end)
