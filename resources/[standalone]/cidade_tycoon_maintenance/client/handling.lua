-- client/handling.lua

local config = require 'config/maintenance'
local appliedHandlingPlates = {}
local appliedTireFailures = {}
local appliedUndriveablePlates = {}

local installedPartEffects = {
    engine_stock = { drive = 1.0, speed = 1.0 },
    filter_performance = { drive = 1.015, speed = 1.0 },
    radiator_heavy_duty = { drive = 1.0, speed = 1.0 },
    ecu_sport_stage = { drive = 1.045, speed = 1.025 },
    turbo_street_kit = { drive = 1.075, speed = 1.03 },
    turbo_kit = { drive = 1.095, speed = 1.045 },
    supercharger_street_kit = { drive = 1.085, speed = 1.025 },

    transmission_stock = { shift = 1.0, speed = 1.0 },
    clutch_performance = { shift = 1.06, speed = 1.0 },
    transmission_street_kit = { shift = 1.055, speed = 1.005 },
    transmission_sport_kit = { shift = 1.1, speed = 1.015 },
    transmission_race_kit = { shift = 1.15, speed = 1.025 },

    drivetrain_factory = { traction = 1.0, speed = 1.0 },
    drivetrain_conversion_fwd = { traction = 1.0, speed = 0.99, driveBiasFront = 1.0, tractionBiasFront = 0.62 },
    drivetrain_conversion_rwd = { traction = 0.98, speed = 1.005, driveBiasFront = 0.0, tractionBiasFront = 0.46 },
    drivetrain_conversion_awd = { traction = 1.035, speed = 0.985, driveBiasFront = 0.5, tractionBiasFront = 0.5 },
    traction_control = { traction = 1.04, speed = 0.995 },

    brakes_stock = { brake = 1.0 },
    brake_street_basic = { brake = 1.03 },
    performance_brakes = { brake = 1.08 },
    brake_sport_kit = { brake = 1.1 },
    brake_race_kit = { brake = 1.14 },

    suspension_stock = { suspension = 1.0, traction = 1.0 },
    suspension_kit = { suspension = 1.03, traction = 1.005 },
    suspension_sport_kit = { suspension = 1.06, traction = 1.015 },
    alignment_standard_service = { suspension = 1.01, traction = 1.01 },

    -- Performance Kits: sobrescrevem os efeitos individuais quando instalados
    performance_kit_drag = {
        drive = 1.28, speed = 1.04, shift = 1.22,
        brake = 1.0, traction = 0.78, suspension = 1.10,
        driveBiasFront = 0.0, tractionBiasFront = 0.40,
    },
    performance_kit_drift = {
        drive = 1.10, speed = 0.97, shift = 1.10,
        brake = 0.92, traction = 0.72, suspension = 0.88,
        driveBiasFront = 0.0, tractionBiasFront = 0.40,
    },
    performance_kit_race = {
        drive = 1.16, speed = 1.06, shift = 1.16,
        brake = 1.16, traction = 1.08, suspension = 1.10,
        driveBiasFront = 0.45, tractionBiasFront = 0.50,
    },
}

local classBalanceCaps = {
    default = { driveMax = 1.14, speedMax = 1.08, brakeMax = 1.16, tractionMax = 1.14, suspensionMax = 1.1, shiftMax = 1.18 },
    [6] = { driveMax = 1.15, speedMax = 1.09, brakeMax = 1.16, tractionMax = 1.14, suspensionMax = 1.1, shiftMax = 1.18 }, -- sports
    [7] = { driveMax = 1.1, speedMax = 1.06, brakeMax = 1.14, tractionMax = 1.1, suspensionMax = 1.08, shiftMax = 1.14 }, -- super
    [8] = { driveMax = 1.1, speedMax = 1.06, brakeMax = 1.12, tractionMax = 1.08, suspensionMax = 1.06, shiftMax = 1.12 }, -- motorcycles
    [9] = { driveMax = 1.1, speedMax = 1.05, brakeMax = 1.14, tractionMax = 1.16, suspensionMax = 1.12, shiftMax = 1.12 }, -- off-road
    [10] = { driveMax = 1.08, speedMax = 1.04, brakeMax = 1.12, tractionMax = 1.1, suspensionMax = 1.08, shiftMax = 1.1 }, -- industrial
    [11] = { driveMax = 1.08, speedMax = 1.04, brakeMax = 1.12, tractionMax = 1.1, suspensionMax = 1.08, shiftMax = 1.1 }, -- utility
    [12] = { driveMax = 1.09, speedMax = 1.05, brakeMax = 1.13, tractionMax = 1.1, suspensionMax = 1.08, shiftMax = 1.1 }, -- vans
    [20] = { driveMax = 1.08, speedMax = 1.04, brakeMax = 1.12, tractionMax = 1.1, suspensionMax = 1.08, shiftMax = 1.1 }, -- commercial
}

local ignoredHandlingClasses = {
    [13] = true, -- cycles
    [14] = true, -- boats
    [15] = true, -- helicopters
    [16] = true, -- planes
    [21] = true, -- trains
}

local function getInstalledEffect(key)
    return installedPartEffects[key] or {}
end

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function healthMultiplier(health, minValue)
    health = clamp(tonumber(health) or 100.0, 0.0, 100.0)

    local deg = config.healthDegradation or {}
    local healthyThreshold = deg.healthyThreshold or 80.0
    local wornThreshold = deg.wornThreshold or 40.0
    local healthySlope = deg.healthySlope or 0.0025
    local wornSlope = deg.wornSlope or 0.0045
    local criticalSlope = deg.criticalSlope or 0.008
    local criticalFloor = deg.criticalFloor or 0.77

    if health >= healthyThreshold then
        return 1.0 - ((100.0 - health) * healthySlope)
    end

    if health >= wornThreshold then
        return 0.95 - ((healthyThreshold - health) * wornSlope)
    end

    return math.max(minValue, criticalFloor - ((wornThreshold - health) * criticalSlope))
end

local function getClassCaps(vehicle)
    return classBalanceCaps[GetVehicleClass(vehicle)] or classBalanceCaps.default
end

local function getFailureConfig()
    return (config.wearModel and config.wearModel.failure) or {}
end

local function splitTransmissionAndDrivetrain(status)
    local transmissionKey = status.installed_transmission or 'transmission_stock'
    local drivetrainKey = status.installed_drivetrain or 'drivetrain_factory'

    -- Backward compatibility for vehicles that stored traction conversions in the old transmission slot.
    if transmissionKey == 'drivetrain_conversion_fwd'
        or transmissionKey == 'drivetrain_conversion_rwd'
        or transmissionKey == 'drivetrain_conversion_awd'
        or transmissionKey == 'traction_control' then
        drivetrainKey = transmissionKey
        transmissionKey = 'transmission_stock'
    end

    return transmissionKey, drivetrainKey
end

-- Helper to retrieve and cache factory handling values locally on the entity to prevent compounding degradation
local function GetBaseHandlingFloat(vehicle, className, fieldName)
    local state = Entity(vehicle).state
    local cacheKey = 'base_handling_' .. fieldName
    local baseValue = state[cacheKey]
    if baseValue == nil then
        local ok, result = pcall(GetVehicleHandlingFloat, vehicle, className, fieldName)
        if not ok or result == 0.0 then
            -- Fallback: return 1.0 for missing/invalid handling fields
            result = 1.0
        end
        baseValue = result
        state:set(cacheKey, baseValue, false) -- Local state bag, do not replicate to server
    end
    return baseValue
end

local function ApplyVehicleHandlingModifiers(vehicle, plate, status)
    if not DoesEntityExist(vehicle) then return end
    if ignoredHandlingClasses[GetVehicleClass(vehicle)] then return end

    -- Extract tire health correctly (supporting both legacy single key and new 4-tire format)
    local tiresHealth = status.tires_health or math.min(
        status.tire_lf_health or 100.0,
        status.tire_rf_health or 100.0,
        status.tire_lr_health or 100.0,
        status.tire_rr_health or 100.0
    )

    -- Detect weather and terrain conditions for realistic handling profiles
    local coords = GetEntityCoords(vehicle)
    local isOffRoad = not IsPointOnRoad(coords.x, coords.y, coords.z, vehicle)
    local rainLevel = GetRainLevel()
    local isRaining = rainLevel > 0.1
    local transmissionKey, drivetrainKey = splitTransmissionAndDrivetrain(status)

    -- Avoid re-applying if nothing changed
    local currentHash = table.concat({
        string.format('%.1f', status.engine_health or 100.0),
        string.format('%.1f', status.transmission_health or 100.0),
        string.format('%.1f', status.battery_health or 100.0),
        string.format('%.1f', status.brakes_health or 100.0),
        string.format('%.1f', status.suspension_health or 100.0),
        string.format('%.1f', tiresHealth),
        status.tire_type or 'standard',
        status.installed_tires or 'tire_street_basic',
        status.installed_engine or 'engine_stock',
        transmissionKey,
        drivetrainKey,
        status.installed_brakes or 'brakes_stock',
        status.installed_suspension or 'suspension_stock',
        status.installed_alignment or 'alignment_standard_service',
        status.installed_performance_kit or 'performance_none',
        tostring(isOffRoad),
        string.format('%.2f', rainLevel),
    }, '_')

    if appliedHandlingPlates[plate] == currentHash then return end

    local caps = getClassCaps(vehicle)

    -- Health only becomes severe below 80%. This keeps normal wear realistic without making cars unusable too early.
    local engMult = healthMultiplier(status.engine_health or 100.0, 0.45)
    local brakeMult = healthMultiplier(status.brakes_health or 100.0, 0.42)
    local suspMult = healthMultiplier(status.suspension_health or 100.0, 0.55)
    local tireMult = healthMultiplier(tiresHealth, 0.35)
    local transMult = healthMultiplier(status.transmission_health or 100.0, 0.5)

    -- Load individual part effects first
    local engineEffect = getInstalledEffect(status.installed_engine or 'engine_stock')
    local transmissionEffect = getInstalledEffect(transmissionKey)
    local drivetrainEffect = getInstalledEffect(drivetrainKey)
    local brakesEffect = getInstalledEffect(status.installed_brakes or 'brakes_stock')
    local suspensionEffect = getInstalledEffect(status.installed_suspension or 'suspension_stock')
    local alignmentEffect = getInstalledEffect(status.installed_alignment or 'alignment_standard_service')

    -- Performance kit: STACKS with individual parts (multiply effects)
    local performanceKit = status.installed_performance_kit
    if performanceKit and installedPartEffects[performanceKit] then
        local kitFx = installedPartEffects[performanceKit]
        engineEffect = {
            drive = (engineEffect.drive or 1.0) * (kitFx.drive or 1.0),
            speed = (engineEffect.speed or 1.0) * (kitFx.speed or 1.0),
        }
        transmissionEffect = {
            shift = (transmissionEffect.shift or 1.0) * (kitFx.shift or 1.0),
            speed = (transmissionEffect.speed or 1.0) * (kitFx.speed or 1.0),
        }
        drivetrainEffect = {
            traction = (drivetrainEffect.traction or 1.0) * (kitFx.traction or 1.0),
            speed = (drivetrainEffect.speed or 1.0) * (kitFx.speed or 1.0),
            driveBiasFront = kitFx.driveBiasFront, -- override (incompatible with part)
            tractionBiasFront = kitFx.tractionBiasFront, -- override
        }
        brakesEffect = {
            brake = (brakesEffect.brake or 1.0) * (kitFx.brake or 1.0),
        }
        suspensionEffect = {
            suspension = (suspensionEffect.suspension or 1.0) * (kitFx.suspension or 1.0),
            traction = (suspensionEffect.traction or 1.0) * (kitFx.traction or 1.0),
        }
        -- Alignment unaffected by kit
    end

    -- Part Multipliers (if specific parts are installed, they can boost base handling)
    local gripModifier = 1.0
    if config and config.partsCatalog then
        local installedTireKey = status.installed_tires or 'tire_street_basic'
        local tireConfig = config.partsCatalog[installedTireKey]
        if tireConfig and tireConfig.effectProfile then
            gripModifier = tireConfig.effectProfile.grip or 1.0

            -- Apply weather penalty (mitigated by tires with good wet profiles)
            if isRaining then
                local wetModifier = tireConfig.effectProfile.wet or 1.0
                -- Apply penalty proportional to rain level (lower wetModifier = worse traction in rain)
                gripModifier = gripModifier * (1.0 + (wetModifier - 1.0) * rainLevel)
            end

            -- Apply offroad terrain penalty (mitigated by offroad tires)
            if isOffRoad then
                local offroadModifier = tireConfig.effectProfile.offroad or 1.0
                gripModifier = gripModifier * offroadModifier
            end
        end
    end
    gripModifier = clamp(gripModifier, 0.42, 1.12)

    local reinforcedMult = 1.0
    if status.tire_type == 'reinforced' then
        reinforcedMult = 0.975 -- Heavier tires slightly reduce launch without punishing trucks too much.
    end

    local isElectric = exports.cidade_tycoon_core:IsVehicleElectric(GetEntityModel(vehicle))

    -- Get EV performance profile if applicable
    local evProfile = nil
    if isElectric then
        local coreConfig = exports.cidade_tycoon_core:GetCoreConfig()
        local evConfig = coreConfig.EVPerformance or {}
        local vehClass = GetVehicleClass(vehicle)
        evProfile = evConfig[vehClass] or evConfig.default or { driveMult = 1.4, speedCap = 1.0, tractionReduction = 0.94 }
    end

    -- Engine / Battery affects Drive Force
    local fInitialDriveForce = GetBaseHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce')
    local driveMult
    if isElectric and evProfile then
        -- Realistic EV: high initial torque from battery, varies by class
        local batteryMult = healthMultiplier(status.battery_health or 100.0, 0.45)
        local baseEvMult = evProfile.driveMult or 1.4
        -- Effective multiplier degrades with battery health
        local effectiveMult = 1.0 + ((baseEvMult - 1.0) * batteryMult)
        driveMult = clamp(effectiveMult * reinforcedMult, 0.45, caps.driveMax * baseEvMult)
    else
        driveMult = clamp(engMult * reinforcedMult * (engineEffect.drive or 1.0), 0.45, caps.driveMax)
    end
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', fInitialDriveForce * driveMult)

    -- Brakes affect Brake Force
    local fBrakeForce = GetBaseHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce')
    local brakeForceMult = clamp(brakeMult * (brakesEffect.brake or 1.0), 0.42, caps.brakeMax)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce', fBrakeForce * brakeForceMult)

    -- Suspension affects suspension force
    local fSuspensionForce = GetBaseHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionForce')
    local suspensionForceMult = clamp(suspMult * (suspensionEffect.suspension or 1.0) * (alignmentEffect.suspension or 1.0), 0.55, caps.suspensionMax)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionForce', fSuspensionForce * suspensionForceMult)

    -- Tires, drivetrain and suspension affect traction.
    local fTractionCurveMax = GetBaseHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax')
    local fTractionCurveMin = GetBaseHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin')
    local drivetrainTraction = drivetrainEffect.traction or 1.0
    local suspensionTraction = suspensionEffect.traction or 1.0
    local alignmentTraction = alignmentEffect.traction or 1.0
    local tractionMult = clamp(tireMult * gripModifier * drivetrainTraction * suspensionTraction * alignmentTraction, 0.42, caps.tractionMax)

    -- EV wheelspin: high-torque EVs lose traction at low speeds (realistic instant torque)
    if isElectric and evProfile and evProfile.tractionReduction then
        local speed = GetEntitySpeed(vehicle)
        if speed < 10.0 then
            local spinAmount = 1.0 - (speed / 10.0)
            tractionMult = tractionMult * (evProfile.tractionReduction + (spinAmount * 0.08))
            tractionMult = clamp(tractionMult, 0.35, caps.tractionMax)
        end
    end

    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax', fTractionCurveMax * tractionMult)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin', fTractionCurveMin * tractionMult)

    -- Transmission affects UpShift / DownShift
    if isElectric then
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleUpShift', 15.0)
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleDownShift', 15.0)
    else
        local fClutchChangeRateScaleUpShift = GetBaseHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleUpShift')
        local fClutchChangeRateScaleDownShift = GetBaseHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleDownShift')
        local shiftMult = clamp(transMult * (transmissionEffect.shift or 1.0), 0.5, caps.shiftMax)
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleUpShift', fClutchChangeRateScaleUpShift * shiftMult)
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleDownShift', fClutchChangeRateScaleDownShift * shiftMult)
    end

    local fDriveBiasFront = GetBaseHandlingFloat(vehicle, 'CHandlingData', 'fDriveBiasFront')
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveBiasFront', drivetrainEffect.driveBiasFront or fDriveBiasFront)

    if drivetrainEffect.tractionBiasFront ~= nil then
        local fTractionBiasFront = GetBaseHandlingFloat(vehicle, 'CHandlingData', 'fTractionBiasFront')
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionBiasFront', clamp(drivetrainEffect.tractionBiasFront, 0.35, 0.75))
    else
        local fTractionBiasFront = GetBaseHandlingFloat(vehicle, 'CHandlingData', 'fTractionBiasFront')
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionBiasFront', fTractionBiasFront)
    end

    local speedMult
    if isElectric then
        local batteryMult = healthMultiplier(status.battery_health or 100.0, 0.45)
        speedMult = batteryMult * (drivetrainEffect.speed or 1.0)
        -- EVs have lower top speed relative to their acceleration (realistic)
        if evProfile and evProfile.speedCap then
            speedMult = math.min(speedMult, caps.speedMax * evProfile.speedCap)
        end
    else
        speedMult = engMult * transMult * (engineEffect.speed or 1.0) * (transmissionEffect.speed or 1.0) * (drivetrainEffect.speed or 1.0)
    end

    if status.tire_type == 'reinforced' then
        speedMult = speedMult * 0.985 -- slightly lower top speed due to weight
    end
    speedMult = clamp(speedMult, 0.5, caps.speedMax)

    local fInitialDriveMaxFlatVel = GetBaseHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel', fInitialDriveMaxFlatVel * speedMult)

    appliedHandlingPlates[plate] = currentHash
end

local tireFailureIndexes = {
    tire_lf_health = 0,
    tire_rf_health = 1,
    tire_lr_health = 4,
    tire_rr_health = 5,
}

local function applyTireFailure(vehicle, plate, status, tireHealthKey, tireIndex, failureConfig)
    local health = tonumber(status[tireHealthKey]) or 100.0
    local punctureHealth = tonumber(failureConfig.tirePunctureHealth) or 12.0
    local burstHealth = tonumber(failureConfig.tireBurstHealth) or 2.0
    local failureKey = plate .. ':' .. tireIndex

    if health <= burstHealth then
        if not IsVehicleTyreBurst(vehicle, tireIndex, true) then
            SetVehicleTyreBurst(vehicle, tireIndex, true, 1000.0)
        end
        appliedTireFailures[failureKey] = 'burst'
        return
    end

    if health <= punctureHealth then
        if not IsVehicleTyreBurst(vehicle, tireIndex, false) then
            SetVehicleTyreBurst(vehicle, tireIndex, false, 100.0)
        end
        appliedTireFailures[failureKey] = 'puncture'
        return
    end

    if health > (punctureHealth + 8.0) and appliedTireFailures[failureKey] then
        SetVehicleTyreFixed(vehicle, tireIndex)
        appliedTireFailures[failureKey] = nil
    end
end

local function ApplyVehicleFailureState(vehicle, plate, status)
    if not DoesEntityExist(vehicle) then return end
    if ignoredHandlingClasses[GetVehicleClass(vehicle)] then return end

    local failureConfig = getFailureConfig()
    local engineHealth = tonumber(status.engine_health) or 100.0
    local transmissionHealth = tonumber(status.transmission_health) or 100.0
    local engineStopHealth = tonumber(failureConfig.engineStopHealth) or 8.0
    local transmissionStopHealth = tonumber(failureConfig.transmissionStopHealth) or 5.0
    local shouldStopVehicle = engineHealth <= engineStopHealth or transmissionHealth <= transmissionStopHealth

    if shouldStopVehicle then
        SetVehicleUndriveable(vehicle, true)
        SetVehicleEngineOn(vehicle, false, true, true)
        appliedUndriveablePlates[plate] = true
    elseif appliedUndriveablePlates[plate] then
        SetVehicleUndriveable(vehicle, false)
        appliedUndriveablePlates[plate] = nil
    end

    if engineHealth <= 25.0 then
        local visualEngineHealth = math.max(120.0, 120.0 + (engineHealth * 12.0))
        if GetVehicleEngineHealth(vehicle) > visualEngineHealth then
            SetVehicleEngineHealth(vehicle, visualEngineHealth)
        end
    end

    for tireHealthKey, tireIndex in pairs(tireFailureIndexes) do
        applyTireFailure(vehicle, plate, status, tireHealthKey, tireIndex, failureConfig)
    end
end

-- Monitor State Bags to apply handling real-time
AddStateBagChangeHandler('tycoon:status', nil, function(bagName, key, value, _reserved, replicated)
    if not value then return end

    local entity = GetEntityFromStateBagName(bagName)
    if not entity or entity == 0 then return end
    if not IsEntityAVehicle(entity) then return end
    if NetworkGetEntityOwner(entity) ~= PlayerId() then return end

    local plate = GetVehicleNumberPlateText(entity)
    if not plate then return end

    ApplyVehicleHandlingModifiers(entity, plate, value)
    ApplyVehicleFailureState(entity, plate, value)
end)

-- Initial apply when entering vehicle
AddEventHandler('qbx_core:client:onVehicleEnter', function(veh, plate)
    local status = Entity(veh).state['tycoon:status']
    if status then
        ApplyVehicleHandlingModifiers(veh, plate, status)
        ApplyVehicleFailureState(veh, plate, status)
    else
        lib.callback('cidade_tycoon_maintenance:server:getVehicleStatus', false, function(data)
            if data then
                local subsystemHealth = {}
                for _, subsystem in ipairs(data.subsystems or {}) do
                    subsystemHealth[subsystem.key] = subsystem.health
                end

                local convertedStatus = {
                    engine_health = subsystemHealth.engine or 100.0,
                    transmission_health = subsystemHealth.transmission or subsystemHealth.drivetrain or 100.0,
                    battery_health = subsystemHealth.battery or 100.0,
                    brakes_health = subsystemHealth.brakes or 100.0,
                    suspension_health = subsystemHealth.suspension or 100.0,
                    tire_lf_health = subsystemHealth.tire_lf or 100.0,
                    tire_rf_health = subsystemHealth.tire_rf or 100.0,
                    tire_lr_health = subsystemHealth.tire_lr or 100.0,
                    tire_rr_health = subsystemHealth.tire_rr or 100.0,
                    tire_type = data.tire_type or 'standard',
                    installed_tires = data.installed_tires or 'tire_street_basic',
                    installed_engine = data.installed_engine or 'engine_stock',
                    installed_transmission = data.installed_transmission or 'transmission_stock',
                    installed_drivetrain = data.installed_drivetrain or 'drivetrain_factory',
                    installed_brakes = data.installed_brakes or 'brakes_stock',
                    installed_suspension = data.installed_suspension or 'suspension_stock',
                    installed_alignment = data.installed_alignment or 'alignment_standard_service'
                }
                Entity(veh).state:set('tycoon:status', convertedStatus, true)
                ApplyVehicleHandlingModifiers(veh, plate, convertedStatus)
                ApplyVehicleFailureState(veh, plate, convertedStatus)
            end
        end, plate)
    end
end)

-- Dynamic thread to update handling modifiers for weather/terrain transitions in real-time
CreateThread(function()
    while true do
        local wait = 2000
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            wait = 1000
            local plate = GetVehicleNumberPlateText(vehicle)
            if plate then
                local status = Entity(vehicle).state['tycoon:status']
                if status then
                    ApplyVehicleHandlingModifiers(vehicle, plate, status)
                    ApplyVehicleFailureState(vehicle, plate, status)
                end
            end
        end
        Wait(wait)
    end
end)
