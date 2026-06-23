-- client/body_damage.lua
-- Monitors visual vehicle damage and syncs it as body_health

local bodyHealthVehicles = {} -- [plate] = body_health

local function normalizePlate(plate)
    return exports.cidade_tycoon_core:NormalizePlate(plate)
end

-- Thresholds for visual damage effects
local BODY_HEALTH_THRESHOLDS = {
    critical = 20,   -- <20%: falhas graves, quase inguinavel
    bad = 40,        -- <40%: problemas visiveis, performance cai
    worn = 60,       -- <60%: dano visual evidente
    ok = 80,         -- <80%: pequenos amassados
}

-- ==========================================
-- CALCULATE BODY HEALTH FROM VISUAL STATE
-- ==========================================

local function calculateVisualDamage(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local dirtLevel = GetVehicleDirtLevel(vehicle)

    -- GTA V scale: 1000.0 = perfect, 0.0 = destroyed
    -- Map to our 0-100 scale
    local gtaBody = (bodyHealth / 1000.0) * 100.0
    local gtaEngine = (engineHealth / 1000.0) * 100.0

    -- Check for missing doors, broken windows, popped tires
    local penalty = 0.0
    local numDoors = GetVehicleNumberOfDoors(vehicle)
    if numDoors then
        for door = 0, numDoors - 1 do
            if IsVehicleDoorDamaged(vehicle, door) then
                penalty = penalty + 5.0 -- -5% per damaged door
            end
        end
    end

    -- Check for broken windows
    for window = 0, 5 do
        if IsVehicleWindowIntact(vehicle, window) == false then
            penalty = penalty + 3.0
        end
    end

    -- Check for broken/burnt lights
    if IsVehicleLightDamaged(vehicle, 0) then penalty = penalty + 2.0 end
    if IsVehicleLightDamaged(vehicle, 1) then penalty = penalty + 2.0 end

    -- Check for missing wheels
    for wheel = 0, 3 do
        if IsVehicleTyreBurst(vehicle, wheel, false) then
            penalty = penalty + 8.0 -- popped tire = serious body damage
        end
    end

    -- Dirt penalty (visual state)
    local dirtPenalty = dirtLevel * 15.0 -- max dirt = -15%

    -- Combine: GTA body health is the base, penalties subtract
    local finalHealth = math.max(0.0, math.min(100.0, gtaBody - penalty - dirtPenalty))
    return finalHealth
end

-- ==========================================
-- SYNC BODY HEALTH TO SERVER
-- ==========================================

local function syncBodyHealth(plate, health)
    plate = normalizePlate(plate)
    local prev = bodyHealthVehicles[plate]
    if prev and math.abs(prev - health) < 2.0 then return end -- skip small changes
    bodyHealthVehicles[plate] = health
    TriggerServerEvent('cidade_tycoon_maintenance:server:updateBodyHealth', plate, math.floor(health))
end

-- ==========================================
-- MAIN MONITOR THREAD
-- ==========================================

CreateThread(function()
    while true do
        Wait(3000) -- check every 3 seconds (not performance-critical)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 then
            local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
            if plate and plate ~= '' then
                local health = calculateVisualDamage(vehicle)
                syncBodyHealth(plate, health)

                -- Check for critical state effects
                local currentHealth = bodyHealthVehicles[plate] or health

                if currentHealth < BODY_HEALTH_THRESHOLDS.critical then
                    -- CRITICAL: car is nearly destroyed
                    -- Effects handled in handling.lua via state bag
                    SetVehicleEngineOn(vehicle, false, false, true)
                    SetVehicleUndriveable(vehicle, true)
                    if math.random() < 0.05 then
                        lib.notify({
                            title = 'Lataria CRITICA',
                            description = 'A lataria do veiculo esta em pessimo estado! Leve ao mecanico URGENTE.',
                            type = 'error',
                            duration = 8000,
                        })
                    end
                elseif currentHealth < BODY_HEALTH_THRESHOLDS.bad then
                    -- BAD: performance issues
                    if math.random() < 0.02 then
                        -- Random engine stutter
                        SetVehicleEnginePowerMultiplier(vehicle, 0.6)
                        SetVehicleCheatPowerIncrease(vehicle, 0.0)
                    else
                        SetVehicleEnginePowerMultiplier(vehicle, 1.0)
                    end
                elseif currentHealth < BODY_HEALTH_THRESHOLDS.worn then
                    -- WORN: visual damage but drivable
                    SetVehicleEnginePowerMultiplier(vehicle, 1.0)
                end

                -- Only update the local state bag after the server has provided a complete status table.
                local currentStatus = Entity(vehicle).state['tycoon:status']
                if type(currentStatus) == 'table' and currentStatus.engine_health ~= nil then
                    local updatedStatus = {}
                    for key, value in pairs(currentStatus) do updatedStatus[key] = value end
                    updatedStatus.body_health = math.floor(currentHealth)
                    Entity(vehicle).state:set('tycoon:status', updatedStatus, true)
                end
            end
        else
            -- Reset multipliers when leaving vehicle
            SetVehicleEnginePowerMultiplier(vehicle, 1.0)
            SetVehicleUndriveable(vehicle, false)
        end
    end
end)

-- ==========================================
-- EXPORTS
-- ==========================================

exports('GetBodyHealth', function(plate)
    return bodyHealthVehicles[normalizePlate(plate)] or 100.0
end)

-- Dev command to check body health
RegisterCommand('bodyhealth', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        lib.notify({ title = 'Body Health', description = 'Voce nao esta em um veiculo.', type = 'error' })
        return
    end
    local plate = GetVehicleNumberPlateText(veh)
    local health = calculateVisualDamage(veh)
    local gtaBody = GetVehicleBodyHealth(veh)
    lib.notify({
        title = 'Body Health',
        description = ('Placa: %s\nSaude: %.0f%%\nGTA Body: %.0f/1000\nPortas danificadas: contando...'):format(plate, health, gtaBody),
        type = 'inform',
        duration = 8000,
    })
end, false)

