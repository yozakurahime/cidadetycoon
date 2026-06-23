local function defaultRepairFatigue()
    return {
        engine = 0.0,
        transmission = 0.0,
        brakes = 0.0,
        suspension = 0.0,
        battery = 0.0,
        tire_lf = 0.0,
        tire_rf = 0.0,
        tire_lr = 0.0,
        tire_rr = 0.0,
    }
end

local function decodeRepairFatigue(value)
    local fatigue = defaultRepairFatigue()
    local decoded = value

    if type(value) == 'string' and value ~= '' then
        local ok, result = pcall(json.decode, value)
        if ok and type(result) == 'table' then decoded = result end
    end

    if type(decoded) == 'table' then
        for key in pairs(fatigue) do
            fatigue[key] = math.max(0.0, tonumber(decoded[key]) or 0.0)
        end
    end

    return fatigue
end

local function encodeRepairFatigue(value)
    return json.encode(decodeRepairFatigue(value))
end

local function normalizePlate(plate)
    if TycoonCore and TycoonCore.NormalizePlate then
        return TycoonCore.NormalizePlate(plate)
    end

    return tostring(plate or ''):gsub('%s+', ''):upper()
end

local function getRepairFatigueKeys(partCategory)
    if partCategory == 'tires' then
        return { 'tire_lf', 'tire_rf', 'tire_lr', 'tire_rr' }
    elseif partCategory and partCategory:find('tire_') then
        return { partCategory }
    elseif partCategory == 'drivetrain' then
        return { 'transmission' }
    end

    return { partCategory }
end

local function addRepairFatigue(statusTable, partCategory)
    local fatigue = decodeRepairFatigue(statusTable.repair_fatigue)
    for _, key in ipairs(getRepairFatigueKeys(partCategory)) do
        if key then
            fatigue[key] = math.min(1.0, (tonumber(fatigue[key]) or 0.0) + 0.18)
        end
    end
    statusTable.repair_fatigue = fatigue
end

-- Initialize Database Columns if missing
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tycoon_vehicle_status (
            plate VARCHAR(20) NOT NULL PRIMARY KEY,
            mileage FLOAT DEFAULT 0.0,
            engine_health FLOAT DEFAULT 100.0,
            transmission_health FLOAT DEFAULT 100.0,
            brakes_health FLOAT DEFAULT 100.0,
            suspension_health FLOAT DEFAULT 100.0,
            tires_health FLOAT DEFAULT 100.0,
            tire_lf_health FLOAT DEFAULT 100.0,
            tire_rf_health FLOAT DEFAULT 100.0,
            tire_lr_health FLOAT DEFAULT 100.0,
            tire_rr_health FLOAT DEFAULT 100.0,
            tire_type VARCHAR(50) DEFAULT 'standard',
            installed_tires VARCHAR(50) DEFAULT 'tire_street_basic',
            installed_engine VARCHAR(50) DEFAULT 'engine_stock',
            installed_transmission VARCHAR(50) DEFAULT 'transmission_stock',
            installed_drivetrain VARCHAR(50) DEFAULT 'drivetrain_factory',
            installed_brakes VARCHAR(50) DEFAULT 'brakes_stock',
            installed_suspension VARCHAR(50) DEFAULT 'suspension_stock',
            installed_alignment VARCHAR(50) DEFAULT 'alignment_standard_service',
            battery_health FLOAT DEFAULT 100.0,
            battery_charge FLOAT DEFAULT 100.0,
            installed_performance_kit VARCHAR(50) DEFAULT NULL,
            body_health FLOAT DEFAULT 100.0,
            repair_fatigue LONGTEXT DEFAULT NULL
        );
    ]])
    MySQL.query.await([[
        ALTER TABLE tycoon_vehicle_status
        ADD COLUMN IF NOT EXISTS tire_lf_health FLOAT DEFAULT 100.0,
        ADD COLUMN IF NOT EXISTS tire_rf_health FLOAT DEFAULT 100.0,
        ADD COLUMN IF NOT EXISTS tire_lr_health FLOAT DEFAULT 100.0,
        ADD COLUMN IF NOT EXISTS tire_rr_health FLOAT DEFAULT 100.0,
        ADD COLUMN IF NOT EXISTS tire_type VARCHAR(50) DEFAULT 'standard',
        ADD COLUMN IF NOT EXISTS installed_tires VARCHAR(50) DEFAULT 'tire_street_basic',
        ADD COLUMN IF NOT EXISTS installed_engine VARCHAR(50) DEFAULT 'engine_stock',
        ADD COLUMN IF NOT EXISTS installed_transmission VARCHAR(50) DEFAULT 'transmission_stock',
        ADD COLUMN IF NOT EXISTS installed_drivetrain VARCHAR(50) DEFAULT 'drivetrain_factory',
        ADD COLUMN IF NOT EXISTS installed_brakes VARCHAR(50) DEFAULT 'brakes_stock',
        ADD COLUMN IF NOT EXISTS installed_suspension VARCHAR(50) DEFAULT 'suspension_stock',
        ADD COLUMN IF NOT EXISTS installed_alignment VARCHAR(50) DEFAULT 'alignment_standard_service',
        ADD COLUMN IF NOT EXISTS battery_health FLOAT DEFAULT 100.0,
        ADD COLUMN IF NOT EXISTS battery_charge FLOAT DEFAULT 100.0,
        ADD COLUMN IF NOT EXISTS installed_performance_kit VARCHAR(50) DEFAULT NULL,
        ADD COLUMN IF NOT EXISTS body_health FLOAT DEFAULT 100.0,
        ADD COLUMN IF NOT EXISTS repair_fatigue LONGTEXT DEFAULT NULL;
    ]])
end)

local function getVehicleStatus(plate)
    plate = normalizePlate(plate)
    if plate == '' then return nil end

    local row = MySQL.single.await([[
        SELECT *
        FROM tycoon_vehicle_status
        WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
        ORDER BY CASE WHEN plate = ? THEN 0 ELSE 1 END
        LIMIT 1
    ]], { plate, plate, plate })
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
            tires_health = 100.0, -- Legacy
            tire_lf_health = 100.0,
            tire_rf_health = 100.0,
            tire_lr_health = 100.0,
            tire_rr_health = 100.0,
            battery_health = 100.0,
            battery_charge = 100.0,
            body_health = 100.0,
            tire_type = 'standard',
            installed_tires = 'tire_street_basic',
            installed_engine = 'engine_stock',
            installed_transmission = 'transmission_stock',
            installed_drivetrain = 'drivetrain_factory',
            installed_brakes = 'brakes_stock',
            installed_suspension = 'suspension_stock',
            installed_alignment = 'alignment_standard_service',
            installed_performance_kit = nil,
            repair_fatigue = defaultRepairFatigue()
        }
    end
    -- Fallback for existing rows without tire_lf_health or custom tire columns
    row.tire_lf_health = row.tire_lf_health or row.tires_health or 100.0
    row.tire_rf_health = row.tire_rf_health or row.tires_health or 100.0
    row.tire_lr_health = row.tire_lr_health or row.tires_health or 100.0
    row.tire_rr_health = row.tire_rr_health or row.tires_health or 100.0
    row.battery_health = row.battery_health or 100.0
    row.battery_charge = row.battery_charge or 100.0
    row.tire_type = row.tire_type or 'standard'
    row.installed_tires = row.installed_tires or 'tire_street_basic'
    row.installed_engine = row.installed_engine or 'engine_stock'
    row.installed_transmission = row.installed_transmission or 'transmission_stock'
    row.installed_drivetrain = row.installed_drivetrain or 'drivetrain_factory'
    row.installed_brakes = row.installed_brakes or 'brakes_stock'
    row.installed_suspension = row.installed_suspension or 'suspension_stock'
    row.installed_alignment = row.installed_alignment or 'alignment_standard_service'
    if row.installed_performance_kit == '' then
        row.installed_performance_kit = nil
    end
    row.body_health = row.body_health or 100.0
    row.repair_fatigue = decodeRepairFatigue(row.repair_fatigue)

    local drivetrainParts = {
        drivetrain_conversion_fwd = true,
        drivetrain_conversion_rwd = true,
        drivetrain_conversion_awd = true,
        traction_control = true,
    }

    if drivetrainParts[row.installed_transmission] and row.installed_drivetrain == 'drivetrain_factory' then
        row.installed_drivetrain = row.installed_transmission
        row.installed_transmission = 'transmission_stock'
        MySQL.update.await([[
            UPDATE tycoon_vehicle_status
            SET installed_transmission = ?, installed_drivetrain = ?
            WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
        ]], { row.installed_transmission, row.installed_drivetrain, plate, plate })
    end

    return row
end

local function updateVehicleStatus(plate, statusTable)
    plate = normalizePlate(plate)
    if plate == '' or type(statusTable) ~= 'table' then return false end

    -- Ensure tires_health reflects the worst individual tire condition for backward compatibility
    statusTable.tires_health = math.min(
        statusTable.tire_lf_health or 100.0,
        statusTable.tire_rf_health or 100.0,
        statusTable.tire_lr_health or 100.0,
        statusTable.tire_rr_health or 100.0
    )

    return MySQL.update.await([[
        UPDATE tycoon_vehicle_status
        SET mileage = ?, engine_health = ?, transmission_health = ?, brakes_health = ?, suspension_health = ?, tires_health = ?,
            tire_lf_health = ?, tire_rf_health = ?, tire_lr_health = ?, tire_rr_health = ?,
            tire_type = ?, installed_tires = ?,
            installed_engine = ?, installed_transmission = ?, installed_drivetrain = ?, installed_brakes = ?, installed_suspension = ?,
            installed_alignment = ?, installed_performance_kit = ?, body_health = ?, battery_health = ?, battery_charge = ?, repair_fatigue = ?
        WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
    ]], {
        statusTable.mileage,
        statusTable.engine_health,
        statusTable.transmission_health,
        statusTable.brakes_health,
        statusTable.suspension_health,
        statusTable.tires_health,
        statusTable.tire_lf_health,
        statusTable.tire_rf_health,
        statusTable.tire_lr_health,
        statusTable.tire_rr_health,
        statusTable.tire_type or 'standard',
        statusTable.installed_tires or 'tire_street_basic',
        statusTable.installed_engine or 'engine_stock',
        statusTable.installed_transmission or 'transmission_stock',
        statusTable.installed_drivetrain or 'drivetrain_factory',
        statusTable.installed_brakes or 'brakes_stock',
        statusTable.installed_suspension or 'suspension_stock',
        statusTable.installed_alignment or 'alignment_standard_service',
        statusTable.installed_performance_kit or '',
        statusTable.body_health or 100.0,
        statusTable.battery_health or 100.0,
        statusTable.battery_charge or 100.0,
        encodeRepairFatigue(statusTable.repair_fatigue),
        plate,
        plate
    })
end

local function applyPartRepair(plate, partCategory, repairValue)
    plate = normalizePlate(plate)
    if plate == '' then return false end

    local status = getVehicleStatus(plate)
    if not status then return false end
    local changed = false

    local function repairValueToCap(current)
        current = current or 100.0
        if current >= 50.0 then return current end
        changed = true
        return math.min(50.0, current + repairValue)
    end

    if partCategory == 'tires' then
        status.tires_health = repairValueToCap(status.tires_health)
        status.tire_lf_health = repairValueToCap(status.tire_lf_health)
        status.tire_rf_health = repairValueToCap(status.tire_rf_health)
        status.tire_lr_health = repairValueToCap(status.tire_lr_health)
        status.tire_rr_health = repairValueToCap(status.tire_rr_health)
    elseif partCategory and partCategory:find('tire_') then
        local column = partCategory .. "_health"
        if status[column] == nil then return false end
        status[column] = repairValueToCap(status[column])
    else
        if partCategory == 'drivetrain' then partCategory = 'transmission' end
        local column = partCategory .. "_health"
        if status[column] == nil then return false end
        status[column] = repairValueToCap(status[column])
    end

    if not changed then return false end
    addRepairFatigue(status, partCategory)
    return updateVehicleStatus(plate, status)
end

exports('GetVehicleStatus', getVehicleStatus)
exports('UpdateVehicleStatus', updateVehicleStatus)
exports('ApplyPartRepair', applyPartRepair)
exports('GetPartData', function(itemName) return TycoonCore.GetPartData(itemName) end)
