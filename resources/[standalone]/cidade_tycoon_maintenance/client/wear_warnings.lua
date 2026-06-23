-- client/wear_warnings.lua
-- Monitors vehicle status and shows warnings at critical health thresholds

local warnedThresholds = {} -- plate_key -> threshold notified
local lastWarningTime = 0
local WARNING_COOLDOWN = 30000 -- 30s between warnings per plate

local function getWorstSubsystem(status)
    if not status then return nil, 100 end
    local minHealth = 100
    local worstKey = nil

    local checks = {
        engine = status.engine_health,
        transmission = status.transmission_health,
        brakes = status.brakes_health,
        suspension = status.suspension_health,
        battery = status.battery_health,
    }

    for key, health in pairs(checks) do
        if health and health < minHealth then
            minHealth = health
            worstKey = key
        end
    end

    -- Check tires (worst of 4)
    local tireHealth = math.min(
        status.tire_lf_health or 100,
        status.tire_rf_health or 100,
        status.tire_lr_health or 100,
        status.tire_rr_health or 100
    )
    if tireHealth < minHealth then
        minHealth = tireHealth
        worstKey = 'tires'
    end

    return worstKey, minHealth
end

local function getHealthLabel(health)
    if health >= 70 then return nil, nil end -- All good
    if health >= 40 then return 'ATENCAO', 'warning' end
    if health >= 15 then return 'CRITICO', 'error' end
    return 'FALHA', 'error'
end

local function getSubsystemLabel(key)
    local labels = {
        engine = 'Motor',
        transmission = 'Transmissao',
        brakes = 'Freios',
        suspension = 'Suspensao',
        tires = 'Pneus',
        battery = 'Bateria',
    }
    return labels[key] or key
end

local function showWearNotification(plate, subsystem, health, level, notifyType)
    local now = GetGameTimer()
    if now - lastWarningTime < 5000 then return end
    lastWarningTime = now

    local warningKey = plate .. '_' .. subsystem .. '_' .. level
    if warnedThresholds[warningKey] and now - warnedThresholds[warningKey] < WARNING_COOLDOWN then
        return
    end
    warnedThresholds[warningKey] = now

    local subLabel = getSubsystemLabel(subsystem)
    -- Clean up old keys to prevent memory leak
    for key, timestamp in pairs(warnedThresholds) do
        if now - timestamp > 300000 then -- 5 min cleanup
            warnedThresholds[key] = nil
        end
    end

    lib.notify({
        title = ('⚠ %s: %s'):format(level, plate),
        description = ('%s com %d%% de saude! Faca a manutencao.'):format(subLabel, math.floor(health)),
        type = notifyType or 'error',
        duration = 6000,
    })
end

-- Monitor state bag changes for the vehicle the player is in
AddStateBagChangeHandler('tycoon:status', nil, function(bagName, key, value, _reserved, replicated)
    if not value then return end

    local entity = GetEntityFromStateBagName(bagName)
    if not entity or entity == 0 then return end
    if not IsEntityAVehicle(entity) then return end
    if NetworkGetEntityOwner(entity) ~= PlayerId() then return end

    local worstKey, minHealth = getWorstSubsystem(value)
    if not worstKey or minHealth >= 70 then return end

    local level, notifyType = getHealthLabel(minHealth)
    if not level then return end

    local plate = GetVehicleNumberPlateText(entity)
    if not plate then return end

    showWearNotification(plate, worstKey, minHealth, level, notifyType)
end)

-- Also check on vehicle enter
AddEventHandler('qbx_core:client:onVehicleEnter', function(veh, plate)
    local status = Entity(veh).state['tycoon:status']
    if not status then return end

    local worstKey, minHealth = getWorstSubsystem(status)
    if not worstKey then return end

    -- Show status on enter regardless of health
    local statusText = 'Motor: %d%% | Freios: %d%% | Pneus: %d%%'
    if minHealth < 70 then
        lib.notify({
            title = ('Diagnostico: %s'):format(plate),
            description = ('%s: %d%% - Faca uma revisao em breve!'):format(getSubsystemLabel(worstKey), math.floor(minHealth)),
            type = minHealth < 40 and 'error' or 'warning',
            duration = 5000,
        })
    end
end)
