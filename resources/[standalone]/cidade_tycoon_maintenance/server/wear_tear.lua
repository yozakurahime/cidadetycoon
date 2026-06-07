local function getVehicleMaintenanceSnapshot(plate)
    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    
    return {
        plate = plate,
        mileage = status.mileage,
        subsystems = {
            { key = 'engine', label = 'Motor', health = status.engine_health, icon = 'engine' },
            { key = 'transmission', label = 'Transmissão', health = status.transmission_health, icon = 'gears' },
            { key = 'brakes', label = 'Freios', health = status.brakes_health, icon = 'brake' },
            { key = 'suspension', label = 'Suspensão', health = status.suspension_health, icon = 'suspension' },
            { key = 'tires', label = 'Pneus', health = status.tires_health, icon = 'tire' },
        }
    }
end

lib.callback.register('cidade_tycoon_maintenance:server:getVehicleStatus', function(source, plate)
    return getVehicleMaintenanceSnapshot(plate)
end)

lib.callback.register('cidade_tycoon_maintenance:server:getVehicleMaintenanceByPlate', function(source, plate)
    return getVehicleMaintenanceSnapshot(plate)
end)

local function getMaintenanceClassMultiplier(plate)
    local vehicleRow = MySQL.single.await('SELECT vehicle FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicleRow then return 1.0 end

    local vehData = exports.cidade_tycoon_core:GetVehicleData(vehicleRow.vehicle)
    local mClass = vehData and vehData.maintenanceClass or 'standard'

    local multipliers = {
        light_work = 1.0,
        utility_work = 1.1,
        commercial = 1.25,
        heavy_duty = 1.5,
        light_sport = 1.2,
        sport = 1.4,
        exotic = 1.8,
        hyper = 2.5
    }

    return multipliers[mClass] or 1.0
end

lib.callback.register('cidade_tycoon_maintenance:server:processVehicleWearSample', function(source, plate, payload)
    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return { ok = false } end

    local kmDriven = payload.distanceKm or 0.0
    local impactScore = payload.impactScore or 0.0
    local harshBrakes = payload.harshBrakes or 0
    
    -- Security Validation: Prevent negative values from malicious clients
    if kmDriven < 0 then kmDriven = 0.0 end
    if impactScore < 0 then impactScore = 0.0 end
    if harshBrakes < 0 then harshBrakes = 0 end

    local factor = 1.0


    -- 1. Base Class Multiplier
    local classMult = getMaintenanceClassMultiplier(plate)
    factor = factor * classMult

    -- 2. Dynamic stress calculation
    if payload.impactScore > 0 then factor = factor + (payload.impactScore * 0.1) end
    if payload.harshBrakes > 0 then factor = factor + (payload.harshBrakes * 0.05) end
    if payload.highRpmSeconds > 5 then factor = factor + 0.1 end
    if payload.offroadSeconds > 5 then factor = factor + 0.15 end

    status.mileage = status.mileage + kmDriven

    -- Degradation formula (Standardized)
    local wear = kmDriven * 0.05 * factor
    status.engine_health = math.max(0.0, status.engine_health - (wear * 1.2))
    status.transmission_health = math.max(0.0, status.transmission_health - wear)
    status.brakes_health = math.max(0.0, status.brakes_health - (wear * 1.5))
    status.suspension_health = math.max(0.0, status.suspension_health - (wear * 0.8))
    status.tires_health = math.max(0.0, status.tires_health - (wear * 2.0))

    exports.cidade_tycoon_core:UpdateVehicleStatus(plate, status)

    return { ok = true, summary = getVehicleMaintenanceSnapshot(plate) }
end)

lib.callback.register('cidade_tycoon_maintenance:server:processWearTear', function(source, plate, kmDriven, stressFactor)
    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    local factor = stressFactor or 1.0

    status.mileage = status.mileage + kmDriven
    
    -- Degradation formula
    local wear = kmDriven * 0.05 * factor
    status.engine_health = math.max(0.0, status.engine_health - (wear * 1.2))
    status.transmission_health = math.max(0.0, status.transmission_health - wear)
    status.brakes_health = math.max(0.0, status.brakes_health - (wear * 1.5))
    status.suspension_health = math.max(0.0, status.suspension_health - (wear * 0.8))
    status.tires_health = math.max(0.0, status.tires_health - (wear * 2.0))

    exports.cidade_tycoon_core:UpdateVehicleStatus(plate, status)
    
    -- Sync to State Bag if vehicle is active
    -- This would be handled by a vehicle manager usually
    return status
end)
