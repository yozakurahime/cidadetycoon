-- server/body_damage.lua
-- Server-side body health handling + repair

local function DebugLog(text, ...)
    print(string.format("^3[Tycoon:BodyDamage]^7 %s", string.format(text, ...)))
end


local function normalizePlate(plate)
    return exports.cidade_tycoon_core:NormalizePlate(plate)
end

local function plateMatches(vehicle, plate)
    return normalizePlate(GetVehicleNumberPlateText(vehicle)) == normalizePlate(plate)
end

local function playerInVehicleWithPlate(source, plate)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local vehicle = GetVehiclePedIsIn(ped, false)
    return vehicle ~= 0 and plateMatches(vehicle, plate)
end

local function playerNearVehicleWithPlate(source, plate, maxDistance)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local playerCoords = GetEntityCoords(ped)
    for _, vehicle in ipairs(GetAllVehicles()) do
        if plateMatches(vehicle, plate) then
            local vehicleCoords = GetEntityCoords(vehicle)
            if #(playerCoords - vehicleCoords) <= (maxDistance or 8.0) then
                return true
            end
        end
    end
    return false
end
local function getVehicleOwnerByPlate(plate)
    local normalizedPlate = normalizePlate(plate)
    return MySQL.single.await([[ 
        SELECT citizenid
        FROM player_vehicles
        WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
        LIMIT 1
    ]], { plate, normalizedPlate })
end
-- Receive body health updates from client
RegisterNetEvent('cidade_tycoon_maintenance:server:updateBodyHealth', function(plate, health)
    plate = normalizePlate(plate)
    health = tonumber(health)
    local src = source
    if not plate or not health then return end
    if not playerInVehicleWithPlate(src, plate) then return end

    -- Only update if significant change (avoid spam)
    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return end

    local prevHealth = status.body_health or 100.0
    if math.abs(prevHealth - health) < 3.0 then return end

    status.body_health = math.max(0.0, math.min(100.0, health))

    -- Check for critical state
    if status.body_health < 20 and prevHealth >= 20 then
        DebugLog("Veiculo %s entrou em estado CRITICO de lataria (saude: %.0f%%)", plate, status.body_health)
        local owner = getVehicleOwnerByPlate(plate)
        if owner then
            -- Notify all players near this vehicle
            local players = GetPlayers()
            for _, srcId in ipairs(players) do
                local ped = GetPlayerPed(srcId)
                local coords = GetEntityCoords(ped)
                local vehCoords = GetEntityCoords(GetPlayerPed(src))
                if #(coords - vehCoords) < 50.0 then
                    TriggerClientEvent('ox_lib:notify', srcId, {
                        title = 'Lataria Critica!',
                        description = ('Veiculo %s esta com a lataria em estado critico! Leve ao mecanico!'):format(plate),
                        type = 'error',
                        duration = 8000,
                    })
                end
            end
        end
    end

    exports.cidade_tycoon_core:UpdateVehicleStatus(plate, status)

    -- Sync state bag
    if SyncVehicleStateBag then
        SyncVehicleStateBag(plate, status)
    elseif exports and exports.cidade_tycoon_maintenance and exports.cidade_tycoon_maintenance.SyncVehicleStateBag then
        exports.cidade_tycoon_maintenance:SyncVehicleStateBag(plate, status)
    end
end)

-- Repair body health (called from mechanic menu)
lib.callback.register('cidade_tycoon_maintenance:server:repairBodyDamage', function(source, plate)
    plate = normalizePlate(plate)
    local src = source
    if not playerNearVehicleWithPlate(src, plate, 8.0) then
        return { ok = false, message = 'Aproxime-se do veiculo para reparar a lataria.' }
    end

    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return { ok = false, message = 'Veiculo nao registrado.' } end

    -- Check if player has advanced repair kit
    local item = exports.ox_inventory:GetItem(src, 'advanced_repair_kit', nil, false)
    if not item or item.count < 1 then
        return { ok = false, message = 'Voce precisa de um Kit de Reparo Avancado para reparar a lataria.' }
    end

    if status.body_health and status.body_health >= 95 then
        return { ok = false, message = 'A lataria ja esta em bom estado.' }
    end

    -- Consume item
    if not exports.ox_inventory:RemoveItem(src, 'advanced_repair_kit', 1) then
        return { ok = false, message = 'Erro ao consumir item.' }
    end

    -- Reset all visual damage
    status.body_health = 100.0

    exports.cidade_tycoon_core:UpdateVehicleStatus(plate, status)

    -- Sync
    if SyncVehicleStateBag then
        SyncVehicleStateBag(plate, status)
    elseif exports and exports.cidade_tycoon_maintenance and exports.cidade_tycoon_maintenance.SyncVehicleStateBag then
        exports.cidade_tycoon_maintenance:SyncVehicleStateBag(plate, status)
    end

    -- The client needs to fix the actual visual damage
    TriggerClientEvent('cidade_tycoon_maintenance:client:fixVisualDamage', src, plate)

    return { ok = true, message = 'Lataria reparada com sucesso! Kit de Reparo Avancado utilizado.' }
end)

-- Body repair via mechanic job (free, using shop equipment)
lib.callback.register('cidade_tycoon_mechanic:server:repairBodyAtShop', function(source, plate)
    plate = normalizePlate(plate)
    local src = source
    if not playerNearVehicleWithPlate(src, plate, 8.0) then
        return { ok = false, message = 'Aproxime-se do veiculo para reparar a lataria.' }
    end

    local job = exports.cidade_tycoon_core:GetPlayerJob(src)
    if not job or job.name ~= 'mechanic' then
        return { ok = false, message = 'Apenas mecanicos podem fazer este reparo.' }
    end

    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return { ok = false, message = 'Veiculo nao registrado.' } end

    status.body_health = 100.0
    exports.cidade_tycoon_core:UpdateVehicleStatus(plate, status)

    if SyncVehicleStateBag then
        SyncVehicleStateBag(plate, status)
    elseif exports and exports.cidade_tycoon_maintenance and exports.cidade_tycoon_maintenance.SyncVehicleStateBag then
        exports.cidade_tycoon_maintenance:SyncVehicleStateBag(plate, status)
    end

    TriggerClientEvent('cidade_tycoon_maintenance:client:fixVisualDamage', src, plate)

    return { ok = true, message = 'Lataria reparada na oficina.' }
end)
