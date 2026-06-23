local function DebugLog(text, ...)
    print(string.format("^4[Tycoon:Server:Maintenance]^7 %s", string.format(text, ...)))
end

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

-- ==========================================
-- DYNAMIC NPC FEES (Guardian Requirement)
-- ==========================================
local function calculateLaborFee(plate, source)
    -- Load config from core (fallback defaults for standalone operation)
    local coreConfig = exports.cidade_tycoon_core:GetCoreConfig()
    local workshopCfg = coreConfig.workshop or {}
    local feeRate = workshopCfg.laborFeeRate or 0.3
    local minFee = workshopCfg.minLaborFee or 1000
    local maxFee = workshopCfg.maxLaborFee or 15000
    local luxuryMult = workshopCfg.luxuryMultiplier or 10
    local freeMaxLevel = workshopCfg.freeTierMaxLevel or 5

    local vehicleRow = getVehicleRowByPlate(plate)
    if not vehicleRow then return 5000 end

    local vehData = exports.cidade_tycoon_core:GetVehicleData(vehicleRow.vehicle)
    local price = vehData and vehData.price or 25000

    -- Base Rule: % of price (Min, Max)
    local fee = math.floor(price * feeRate)
    fee = math.max(minFee, math.min(maxFee, fee))

    -- 1. Regra de Isenção para Novatos (Tier 0 até Level 5)
    if source then
        local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
        local isTier0 = vehData and vehData.tier == 0
        local isLowLevel = profile and profile.level <= freeMaxLevel
        if isTier0 and isLowLevel then
            return 0
        end
    end

    -- 2. Multiplicador de Luxo (10x para Super e Hyper)
    if vehData and (vehData.category == 'super' or vehData.category == 'hyper' or vehData.maintenanceClass == 'hyper' or vehData.maintenanceClass == 'exotic') then
        fee = fee * luxuryMult
    end

    return fee
end

-- ==========================================
-- WEAR PROCESSING & SECURITY (Unificado em server/wear_tear.lua)
-- ==========================================

-- ==========================================
-- WORKSHOP CALLBACKS
-- ==========================================

lib.callback.register('cidade_tycoon_maintenance:server:getWorkshopVehicleData', function(source, plate)
    plate = normalizePlate(plate)
    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return nil end

    local isElectric = isVehicleElectricByPlate(plate)

    if isElectric then
        return {
            overallCondition = ((status.battery_health or 100.0) + status.brakes_health + status.suspension_health + status.tires_health) / 4.0,
            subsystems = {
                battery = { label = 'Bateria', condition = status.battery_health or 100.0 },
                brakes = { label = 'Freios', condition = status.brakes_health },
                suspension = { label = 'Suspensão', condition = status.suspension_health },
                tires = { label = 'Pneus', condition = status.tires_health },
            },
            laborFee = calculateLaborFee(plate, source)
        }
    else
        return {
            overallCondition = (status.engine_health + status.transmission_health + status.brakes_health + status.suspension_health + status.tires_health) / 5.0,
            subsystems = {
                engine = { label = 'Motor', condition = status.engine_health },
                transmission = { label = 'Transmissão', condition = status.transmission_health },
                brakes = { label = 'Freios', condition = status.brakes_health },
                suspension = { label = 'Suspensão', condition = status.suspension_health },
                tires = { label = 'Pneus', condition = status.tires_health },
            },
            laborFee = calculateLaborFee(plate, source)
        }
    end
end)

lib.callback.register('cidade_tycoon_maintenance:server:repairSubsystem', function(source, plate, subsystemKey)
    plate = normalizePlate(plate)
    local src = source
    local laborFee = calculateLaborFee(plate, src)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)

    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return { ok = false, message = 'Veiculo nao registrado.' } end

    local currentCondition
    if subsystemKey == 'tires' then
        currentCondition = math.min(status.tire_lf_health or 100.0, status.tire_rf_health or 100.0, status.tire_lr_health or 100.0, status.tire_rr_health or 100.0)
    elseif subsystemKey == 'drivetrain' then
        currentCondition = status.transmission_health
    else
        currentCondition = status[subsystemKey .. '_health']
    end

    if currentCondition and currentCondition >= 50.0 then
        return { ok = false, message = 'Este subsistema ja esta em 50% ou mais. Use troca de peca para restaurar 100%.' }
    end

    if laborFee > 0 and exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < laborFee then
        return { ok = false, message = ('Saldo insuficiente para mão de obra ($%d).'):format(laborFee) }
    end

    -- Process Repair via Core
    local successRemoval = true
    if laborFee > 0 then
        successRemoval = exports.cidade_tycoon_core:RemoveMoney(player, 'bank', laborFee, 'tycoon-npc-repair')
    end

    if successRemoval then
        local success = exports.cidade_tycoon_core:ApplyPartRepair(plate, subsystemKey, 25.0) -- Repair 25% condition
        if success then
            local updatedStatus = exports.cidade_tycoon_core:GetVehicleStatus(plate)
            if updatedStatus and SyncVehicleStateBag then
                SyncVehicleStateBag(plate, updatedStatus)
            elseif updatedStatus and exports.cidade_tycoon_maintenance.SyncVehicleStateBag then
                exports.cidade_tycoon_maintenance:SyncVehicleStateBag(plate, updatedStatus)
            end

            if laborFee > 0 then
                exports.cidade_tycoon_core:LogTransaction(src, laborFee, 'expense', 'repair', 'Manutenção NPC: ' .. subsystemKey)
            end
            local msg = (laborFee == 0) and 'Reparo paliativo gratuito concluido ate o limite de 50%.' or ('Subsistema %s reparado ate no maximo 50%% por $%d. Desgaste futuro aumentado.'):format(subsystemKey, laborFee)
            return { ok = true, message = msg }
        end
    end
    return { ok = false, message = 'Falha no reparo.' }
end)
