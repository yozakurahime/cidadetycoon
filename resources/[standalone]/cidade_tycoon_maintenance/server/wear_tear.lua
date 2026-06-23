local config = require 'config/maintenance'
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

local function plateMatches(vehicle, plate)
    return normalizePlate(GetVehicleNumberPlateText(vehicle)) == normalizePlate(plate)
end

local function playerInVehicleWithPlate(source, plate)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local vehicle = GetVehiclePedIsIn(ped, false)
    return vehicle ~= 0 and plateMatches(vehicle, plate)
end
local function isVehicleElectricByPlate(plate)
    local vehicleRow = getVehicleRowByPlate(plate)
    if vehicleRow then
        return exports.cidade_tycoon_core:IsVehicleElectric(vehicleRow.vehicle)
    end

    local vehicles = GetAllVehicles()
    for _, veh in ipairs(vehicles) do
        if plateMatches(veh, plate) then
            return exports.cidade_tycoon_core:IsVehicleElectric(GetEntityModel(veh))
        end
    end
    return false
end

local function getVehicleMaintenanceSnapshot(plate)
    plate = normalizePlate(plate)
    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return nil end

    local isElectric = isVehicleElectricByPlate(plate)

    local wearModel = (config and config.wearModel) or {}
    local targetLifespanKm = wearModel.targetLifespanKm or {}
    local repairFatigueConfig = wearModel.repairFatigue or {}

    local function getRepairFatigue(subsystemKey)
        local repairFatigue = status.repair_fatigue
        if type(repairFatigue) ~= 'table' then repairFatigue = {} end

        local key = subsystemKey == 'drivetrain' and 'transmission' or subsystemKey
        local extra = tonumber(repairFatigue[key]) or 0.0
        local maxExtraWear = tonumber(repairFatigueConfig.maxExtraWear) or 1.0
        return math.min(maxExtraWear, math.max(0.0, extra))
    end

    local function getKmRemaining(subsystemKey, health)
        local lifespan = tonumber(targetLifespanKm[subsystemKey]) or 8000
        return math.floor((health / 100.0) * lifespan)
    end

    local subsystems = {}
    if isElectric then
        subsystems[#subsystems + 1] = { key = 'battery', label = 'Bateria', health = status.battery_health or 100.0, icon = 'bolt', kmRemaining = getKmRemaining('battery', status.battery_health or 100.0) }
    else
        subsystems[#subsystems + 1] = { key = 'engine', label = 'Motor', health = status.engine_health or 100.0, icon = 'engine', kmRemaining = getKmRemaining('engine', status.engine_health or 100.0) }
        subsystems[#subsystems + 1] = { key = 'transmission', label = 'Transmissao', health = status.transmission_health or 100.0, icon = 'gears', kmRemaining = getKmRemaining('transmission', status.transmission_health or 100.0) }
    end
    subsystems[#subsystems + 1] = { key = 'drivetrain', label = 'Tracao / Controle', health = status.transmission_health or 100.0, icon = 'route', kmRemaining = getKmRemaining('transmission', status.transmission_health or 100.0) }
    subsystems[#subsystems + 1] = { key = 'brakes', label = 'Freios', health = status.brakes_health or 100.0, icon = 'brake', kmRemaining = getKmRemaining('brakes', status.brakes_health or 100.0) }
    subsystems[#subsystems + 1] = { key = 'suspension', label = 'Suspensao', health = status.suspension_health or 100.0, icon = 'suspension', kmRemaining = getKmRemaining('suspension', status.suspension_health or 100.0) }

    -- For tires, use the average of all 4
    local tireAvgHealth = math.floor((
        (status.tire_lf_health or 100.0) +
        (status.tire_rf_health or 100.0) +
        (status.tire_lr_health or 100.0) +
        (status.tire_rr_health or 100.0)
    ) / 4.0)
    local tireKmRemaining = getKmRemaining('tires', tireAvgHealth)

    subsystems[#subsystems + 1] = { key = 'tire_lf', label = 'Pneu Diant. Esquerdo', health = status.tire_lf_health or 100.0, icon = 'tire', kmRemaining = tireKmRemaining }
    subsystems[#subsystems + 1] = { key = 'tire_rf', label = 'Pneu Diant. Direito', health = status.tire_rf_health or 100.0, icon = 'tire', kmRemaining = tireKmRemaining }
    subsystems[#subsystems + 1] = { key = 'tire_lr', label = 'Pneu Tras. Esquerdo', health = status.tire_lr_health or 100.0, icon = 'tire', kmRemaining = tireKmRemaining }
    subsystems[#subsystems + 1] = { key = 'tire_rr', label = 'Pneu Tras. Direito', health = status.tire_rr_health or 100.0, icon = 'tire', kmRemaining = tireKmRemaining }

    for _, sub in ipairs(subsystems) do
        sub.repairFatigue = getRepairFatigue(sub.key)
        sub.kmRemaining = math.floor((sub.kmRemaining or 0) / (1.0 + sub.repairFatigue))
    end

    return {
        plate = plate,
        mileage = status.mileage,
        battery_charge = isElectric and (status.battery_charge or 100.0) or nil,
        body_health = status.body_health or 100.0,
        tire_type = status.tire_type or 'standard',
        installed_tires = status.installed_tires or 'tire_street_basic',
        installed_engine = isElectric and 'battery' or (status.installed_engine or 'engine_stock'),
        installed_transmission = isElectric and 'transmission_electric' or (status.installed_transmission or 'transmission_stock'),
        installed_drivetrain = status.installed_drivetrain or 'drivetrain_factory',
        installed_brakes = status.installed_brakes or 'brakes_stock',
        installed_suspension = status.installed_suspension or 'suspension_stock',
        installed_alignment = status.installed_alignment or 'alignment_standard_service',
        installed_performance_kit = status.installed_performance_kit or nil,
        repair_fatigue = status.repair_fatigue or {},
        subsystems = subsystems
    }
end

lib.callback.register('cidade_tycoon_maintenance:server:getVehicleStatus', function(source, plate)
    return getVehicleMaintenanceSnapshot(plate)
end)

lib.callback.register('cidade_tycoon_maintenance:server:getVehicleMaintenanceByPlate', function(source, plate)
    return getVehicleMaintenanceSnapshot(plate)
end)

local function getMaintenanceClassMultiplier(plate)
    plate = normalizePlate(plate)
    local vehicleRow = getVehicleRowByPlate(plate)
    if not vehicleRow then return 1.0 end

    local vehData = exports.cidade_tycoon_core:GetVehicleData(vehicleRow.vehicle)
    local mClass = vehData and vehData.maintenanceClass or 'standard'
    local wearModel = config.wearModel or {}
    local multipliers = wearModel.maintenanceClassMultiplier or {}

    return multipliers[mClass] or 1.0
end

function SyncVehicleStateBag(plate, status)
    local vehicles = GetAllVehicles()
    local isElectric = isVehicleElectricByPlate(plate)
    for _, veh in ipairs(vehicles) do
        if plateMatches(veh, plate) then
            local tiresHealth = status.tires_health or math.min(
                status.tire_lf_health or 100.0,
                status.tire_rf_health or 100.0,
                status.tire_lr_health or 100.0,
                status.tire_rr_health or 100.0
            )
            local worstCondition
            if isElectric then
                worstCondition = math.min(
                    status.battery_health or 100.0, status.brakes_health, status.suspension_health,
                    status.tire_lf_health, status.tire_rf_health, status.tire_lr_health, status.tire_rr_health
                )
            else
                worstCondition = math.min(
                    status.engine_health, status.transmission_health, status.brakes_health, status.suspension_health,
                    status.tire_lf_health, status.tire_rf_health, status.tire_lr_health, status.tire_rr_health
                )
            end
            Entity(veh).state:set('tycoon:status', {
                mileage = status.mileage,
                condition = worstCondition,
                engine_health = isElectric and 100.0 or status.engine_health,
                transmission_health = isElectric and 100.0 or status.transmission_health,
                battery_health = status.battery_health or 100.0,
                battery_charge = status.battery_charge or 100.0,
                body_health = status.body_health or 100.0,
                brakes_health = status.brakes_health,
                suspension_health = status.suspension_health,
                tires_health = tiresHealth,
                tire_lf_health = status.tire_lf_health,
                tire_rf_health = status.tire_rf_health,
                tire_lr_health = status.tire_lr_health,
                tire_rr_health = status.tire_rr_health,
                tire_type = status.tire_type or 'standard',
                installed_tires = status.installed_tires or 'tire_street_basic',
                installed_engine = isElectric and 'battery' or (status.installed_engine or 'engine_stock'),
                installed_transmission = isElectric and 'transmission_electric' or (status.installed_transmission or 'transmission_stock'),
                installed_drivetrain = status.installed_drivetrain or 'drivetrain_factory',
                installed_brakes = status.installed_brakes or 'brakes_stock',
                installed_suspension = status.installed_suspension or 'suspension_stock',
                installed_alignment = status.installed_alignment or 'alignment_standard_service',
                installed_performance_kit = status.installed_performance_kit or nil,
                repair_fatigue = status.repair_fatigue or {}
            }, true)
            break
        end
    end
end

exports('SyncVehicleStateBag', SyncVehicleStateBag)

-- ==========================================
-- CENTRALIZED WEAR CALCULATION ENGINE
-- ==========================================

local function getNestedNumber(root, groupKey, valueKey, fallback)
    local group = root and root[groupKey]
    if group and group[valueKey] ~= nil then
        return tonumber(group[valueKey]) or fallback
    end

    return fallback
end

local function wearByDistance(subsystem, kmDriven, factor, rateMultiplier)
    local wearModel = config.wearModel or {}
    local targetLifespanKm = wearModel.targetLifespanKm or {}
    local lifespanKm = tonumber(targetLifespanKm[subsystem]) or 8000

    return (kmDriven * 100.0 / lifespanKm) * factor * (rateMultiplier or 1.0)
end

local function getRepairFatigue(status, subsystemKey)
    local repairFatigue = status.repair_fatigue
    if type(repairFatigue) ~= 'table' then repairFatigue = {} end

    local key = subsystemKey == 'drivetrain' and 'transmission' or subsystemKey
    local extra = tonumber(repairFatigue[key]) or 0.0
    local maxExtraWear = tonumber(config.wearModel and config.wearModel.repairFatigue and config.wearModel.repairFatigue.maxExtraWear) or 1.0
    return math.min(maxExtraWear, math.max(0.0, extra))
end

local function applyRepairFatigue(status, subsystemKey, wearAmount)
    return wearAmount * (1.0 + getRepairFatigue(status, subsystemKey))
end

local function calculateWear(status, kmDriven, factor, extraParams)
    extraParams = extraParams or {}
    local impactScore = extraParams.impactScore or 0.0
    local abuseWear = (config.wearModel and config.wearModel.abuseWear) or {}

    status.mileage = status.mileage + kmDriven

    local wearProfile = {
        filter_performance = { engine = 1.01 },
        radiator_heavy_duty = { engine = 0.9 },
        ecu_sport_stage = { engine = 1.06 },
        turbo_street_kit = { engine = 1.1, transmission = 1.03 },
        turbo_kit = { engine = 1.12, transmission = 1.04 },
        supercharger_street_kit = { engine = 1.1, transmission = 1.04 },
        clutch_performance = { transmission = 0.96 },
        transmission_street_kit = { transmission = 1.02 },
        transmission_sport_kit = { transmission = 1.05 },
        transmission_race_kit = { transmission = 1.08 },
        drivetrain_conversion_fwd = { transmission = 0.98, tires = 1.01 },
        drivetrain_conversion_rwd = { transmission = 1.02, tires = 1.02 },
        drivetrain_conversion_awd = { transmission = 1.06, tires = 1.03 },
        traction_control = { brakes = 0.98, tires = 0.94 },
        performance_brakes = { brakes = 0.98 },
        brake_sport_kit = { brakes = 0.96 },
        brake_race_kit = { brakes = 0.94 },
        suspension_kit = { suspension = 0.98 },
        suspension_sport_kit = { suspension = 1.03, tires = 1.01 },
        alignment_standard_service = { suspension = 0.98, tires = 0.97 },
        performance_kit_drag = { engine = 1.24, transmission = 1.18, brakes = 1.08, suspension = 1.08, tires = 1.18 },
        performance_kit_drift = { engine = 1.08, transmission = 1.08, brakes = 1.04, suspension = 1.1, tires = 1.2 },
        performance_kit_race = { engine = 1.12, transmission = 1.1, brakes = 1.08, suspension = 1.08, tires = 1.1 },
    }

    local engineWearRate = 1.0
    local transmissionWearRate = 1.0
    local brakesWearRate = 1.0
    local suspensionWearRate = 1.0
    local tireWearRate = 1.0

    local function applyWearProfile(itemKey)
        local profile = wearProfile[itemKey]
        if not profile then return end

        engineWearRate = engineWearRate * (profile.engine or 1.0)
        transmissionWearRate = transmissionWearRate * (profile.transmission or 1.0)
        brakesWearRate = brakesWearRate * (profile.brakes or 1.0)
        suspensionWearRate = suspensionWearRate * (profile.suspension or 1.0)
        tireWearRate = tireWearRate * (profile.tires or 1.0)
    end

    local installedTransmission = status.installed_transmission or 'transmission_stock'
    local installedDrivetrain = status.installed_drivetrain or 'drivetrain_factory'
    if installedTransmission == 'drivetrain_conversion_fwd'
        or installedTransmission == 'drivetrain_conversion_rwd'
        or installedTransmission == 'drivetrain_conversion_awd'
        or installedTransmission == 'traction_control' then
        installedDrivetrain = installedTransmission
        installedTransmission = 'transmission_stock'
    end

    applyWearProfile(status.installed_engine or 'engine_stock')
    applyWearProfile(installedTransmission)
    applyWearProfile(installedDrivetrain)
    applyWearProfile(status.installed_brakes or 'brakes_stock')
    applyWearProfile(status.installed_suspension or 'suspension_stock')
    applyWearProfile(status.installed_alignment or 'alignment_standard_service')
    applyWearProfile(status.installed_performance_kit)

    -- Get tire wear rate from installed parts
    if config and config.partsCatalog then
        local installedTireKey = status.installed_tires or 'tire_street_basic'
        local tireConfig = config.partsCatalog[installedTireKey]
        if tireConfig and tireConfig.effectProfile and tireConfig.effectProfile.wearRate then
            tireWearRate = tireWearRate * tireConfig.effectProfile.wearRate
        end
    end

    local tireWear = wearByDistance('tires', kmDriven, factor, tireWearRate)
    if status.tire_type == 'reinforced' then
        tireWear = tireWear * 0.6
    end
    tireWear = tireWear
        + (impactScore * getNestedNumber(abuseWear, 'impact', 'tires', 0.006))

    local isElectric = isVehicleElectricByPlate(status.plate)
    local engineWear = 0.0
    local transmissionWear = 0.0
    local batteryWear = 0.0

    if isElectric then
        batteryWear = wearByDistance('battery', kmDriven, factor, 1.0)
            + (impactScore * getNestedNumber(abuseWear, 'impact', 'battery', 0.010))
        batteryWear = applyRepairFatigue(status, 'battery', batteryWear)

        -- battery_charge depletes with distance (like fuel for EVs)
        local chargeConsumption = kmDriven * 0.15 * factor
        status.battery_charge = math.max(0.0, (status.battery_charge or 100.0) - chargeConsumption)

        -- body_health degrades from vibration/wear
        status.body_health = math.max(0.0, (status.body_health or 100.0) - (kmDriven * 0.02 * factor))
    else
        engineWear = wearByDistance('engine', kmDriven, factor, engineWearRate)
            + (impactScore * getNestedNumber(abuseWear, 'impact', 'engine', 0.010))
        engineWear = applyRepairFatigue(status, 'engine', engineWear)

        transmissionWear = wearByDistance('transmission', kmDriven, factor, transmissionWearRate)
            + (impactScore * getNestedNumber(abuseWear, 'impact', 'transmission', 0.004))
        transmissionWear = applyRepairFatigue(status, 'transmission', transmissionWear)

        -- body_health degrades from vibration/wear
        status.body_health = math.max(0.0, (status.body_health or 100.0) - (kmDriven * 0.025 * factor))
    end

    local brakesWear = wearByDistance('brakes', kmDriven, factor, brakesWearRate)
        + (impactScore * getNestedNumber(abuseWear, 'impact', 'brakes', 0.003))
    brakesWear = applyRepairFatigue(status, 'brakes', brakesWear)

    local suspensionWear = wearByDistance('suspension', kmDriven, factor, suspensionWearRate)
        + (impactScore * getNestedNumber(abuseWear, 'impact', 'suspension', 0.030))
    suspensionWear = applyRepairFatigue(status, 'suspension', suspensionWear)

    local tireLfWear = applyRepairFatigue(status, 'tire_lf', tireWear)
    local tireRfWear = applyRepairFatigue(status, 'tire_rf', tireWear)
    local tireLrWear = applyRepairFatigue(status, 'tire_lr', tireWear)
    local tireRrWear = applyRepairFatigue(status, 'tire_rr', tireWear)

    -- Apply subsystem wear
    if isElectric then
        status.battery_health = math.max(0.0, (status.battery_health or 100.0) - batteryWear)
        status.engine_health = 100.0
        status.transmission_health = 100.0
    else
        status.engine_health = math.max(0.0, (status.engine_health or 100.0) - engineWear)
        status.transmission_health = math.max(0.0, (status.transmission_health or 100.0) - transmissionWear)
    end
    status.brakes_health = math.max(0.0, (status.brakes_health or 100.0) - brakesWear)
    status.suspension_health = math.max(0.0, (status.suspension_health or 100.0) - suspensionWear)

    status.tire_lf_health = math.max(0.0, (status.tire_lf_health or 100.0) - tireLfWear)
    status.tire_rf_health = math.max(0.0, (status.tire_rf_health or 100.0) - tireRfWear)
    status.tire_lr_health = math.max(0.0, (status.tire_lr_health or 100.0) - tireLrWear)
    status.tire_rr_health = math.max(0.0, (status.tire_rr_health or 100.0) - tireRrWear)
    status.tires_health = math.min(status.tire_lf_health, status.tire_rf_health, status.tire_lr_health, status.tire_rr_health)
end

lib.callback.register('cidade_tycoon_maintenance:server:processVehicleWearSample', function(source, plate, payload)
    payload = type(payload) == 'table' and payload or {}
    plate = normalizePlate(plate)
    if not playerInVehicleWithPlate(source, plate) then
        return { ok = false, message = 'Veiculo invalido para amostra de desgaste.' }
    end
    if not exports.cidade_tycoon_core:CheckRateLimit(source, 'wear_sample_' .. plate, 1000) then
        return { ok = false, message = 'Aguarde antes de enviar outra amostra.' }
    end

    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return { ok = false } end

    local kmDriven = math.max(0, payload.distanceKm or 0.0)
    local impactScore = math.min(math.max(0, payload.impactScore or 0.0), 250.0)

    local factor = 1.0 * getMaintenanceClassMultiplier(plate)

    calculateWear(status, kmDriven, factor, {
        impactScore = impactScore,
    })

    exports.cidade_tycoon_core:UpdateVehicleStatus(plate, status)
    SyncVehicleStateBag(plate, status)

    return { ok = true, summary = getVehicleMaintenanceSnapshot(plate) }
end)

lib.callback.register('cidade_tycoon_maintenance:server:processWearTear', function(source, plate, kmDriven)
    plate = normalizePlate(plate)
    if not playerInVehicleWithPlate(source, plate) then
        return nil
    end
    if not exports.cidade_tycoon_core:CheckRateLimit(source, 'wear_tear_' .. plate, 500) then
        return nil
    end

    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return nil end

    local factor = getMaintenanceClassMultiplier(plate)

    calculateWear(status, math.max(0, kmDriven or 0), factor, {})

    exports.cidade_tycoon_core:UpdateVehicleStatus(plate, status)
    SyncVehicleStateBag(plate, status)

    return status
end)
