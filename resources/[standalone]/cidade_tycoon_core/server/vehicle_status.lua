local function getVehicleStatus(plate)
    local row = MySQL.single.await('SELECT * FROM tycoon_vehicle_status WHERE plate = ?', { plate })
    if not row then
        -- Initialize status
        MySQL.insert.await([[
            INSERT INTO tycoon_vehicle_status (plate)
            VALUES (?)
        ]], { plate })
        
        return {
            plate = plate,
            mileage = 0.0,
            engine_health = 100.0,
            transmission_health = 100.0,
            brakes_health = 100.0,
            suspension_health = 100.0,
            tires_health = 100.0
        }
    end
    return row
end

local function updateVehicleStatus(plate, statusTable)
    return MySQL.update.await([[
        UPDATE tycoon_vehicle_status
        SET mileage = ?, engine_health = ?, transmission_health = ?, brakes_health = ?, suspension_health = ?, tires_health = ?
        WHERE plate = ?
    ]], {
        statusTable.mileage,
        statusTable.engine_health,
        statusTable.transmission_health,
        statusTable.brakes_health,
        statusTable.suspension_health,
        statusTable.tires_health,
        plate
    })
end

local function applyPartRepair(plate, partCategory, repairValue)
    local status = getVehicleStatus(plate)
    local column = partCategory .. "_health"
    if status[column] == nil then return false end

    local newHealth = math.min(100.0, status[column] + repairValue)
    status[column] = newHealth

    return updateVehicleStatus(plate, status)
end

exports('GetVehicleStatus', getVehicleStatus)
exports('UpdateVehicleStatus', updateVehicleStatus)
exports('ApplyPartRepair', applyPartRepair)
exports('GetPartData', function(itemName) return TycoonCore.GetPartData(itemName) end)
