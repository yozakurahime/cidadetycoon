local function DebugLog(text, ...)
    print(string.format("^4[Tycoon:Server:Maintenance]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- DYNAMIC NPC FEES (Guardian Requirement)
-- ==========================================
local function calculateLaborFee(plate, source)
    local vehicleRow = MySQL.single.await('SELECT vehicle FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicleRow then return 5000 end

    local vehData = exports.cidade_tycoon_core:GetVehicleData(vehicleRow.vehicle)
    local price = vehData and vehData.price or 25000
    
    -- Base Rule: 30% of price (Min $1,000, Max $15,000)
    local fee = math.floor(price * 0.3)
    fee = math.max(1000, math.min(15000, fee))

    -- 1. Regra de Isenção para Novatos (Tier 0 até Level 5)
    if source then
        local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
        local isTier0 = vehData and vehData.tier == 0
        local isLowLevel = profile and profile.level <= 5
        if isTier0 and isLowLevel then
            return 0
        end
    end

    -- 2. Multiplicador de Luxo (10x para Super e Hyper)
    if vehData and (vehData.category == 'super' or vehData.category == 'hyper' or vehData.maintenanceClass == 'hyper' or vehData.maintenanceClass == 'exotic') then
        fee = fee * 10
    end

    return fee
end

-- ==========================================
-- WEAR PROCESSING & SECURITY
-- ==========================================

RegisterNetEvent('cidade_tycoon_maintenance:server:flushWearSample', function(plate, kmDriven, timeDelta)
    local src = source
    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return end

    -- 1. Anti-Cheat: Reject samples > 500km/h average (Guardian Rule)
    if kmDriven > 0 and timeDelta > 0 then
        local avgSpeed = (kmDriven / (timeDelta / 3600))
        if avgSpeed > 500.0 then
            DebugLog("Jogador %d reportou velocidade impossível (%.1f km/h). Ignorando amostra.", src, avgSpeed)
            return
        end
    end

    -- 2. Base Class Multiplier
    local vehicleRow = MySQL.single.await('SELECT vehicle FROM player_vehicles WHERE plate = ?', { plate })
    local vehData = vehicleRow and exports.cidade_tycoon_core:GetVehicleData(vehicleRow.vehicle)
    local factor = (vehData and vehData.maintenanceClass == 'heavy_duty') and 1.5 or 1.0

    -- 3. Apply Degradation
    status.mileage = status.mileage + kmDriven
    local wear = kmDriven * 0.05 * factor
    status.engine_health = math.max(0.0, status.engine_health - (wear * 1.2))
    status.transmission_health = math.max(0.0, status.transmission_health - wear)
    status.brakes_health = math.max(0.0, status.brakes_health - (wear * 1.5))
    status.suspension_health = math.max(0.0, status.suspension_health - (wear * 0.8))
    status.tires_health = math.max(0.0, status.tires_health - (wear * 2.0))

    exports.cidade_tycoon_core:UpdateVehicleStatus(plate, status)

    -- 4. Sync to Entity State Bag (HUD Optimization)
    local vehicles = GetAllVehicles()
    for _, veh in ipairs(vehicles) do
        if GetVehicleNumberPlateText(veh) == plate then
            local worstCondition = math.min(status.engine_health, status.transmission_health, status.brakes_health, status.suspension_health, status.tires_health)
            Entity(veh).state:set('tycoon:status', { mileage = status.mileage, condition = worstCondition }, true)
            break
        end
    end
end)

-- ==========================================
-- WORKSHOP CALLBACKS
-- ==========================================

lib.callback.register('cidade_tycoon_maintenance:server:getWorkshopVehicleData', function(source, plate)
    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return nil end

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
end)

lib.callback.register('cidade_tycoon_maintenance:server:repairSubsystem', function(source, plate, subsystemKey)
    local src = source
    local laborFee = calculateLaborFee(plate, src)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    
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
            if laborFee > 0 then
                exports.cidade_tycoon_core:LogTransaction(src, laborFee, 'expense', 'repair', 'Manutenção NPC: ' .. subsystemKey)
            end
            local msg = (laborFee == 0) and 'Manutenção gratuita (Iniciante) concluída!' or ('Subsistema %s reparado por $%d!'):format(subsystemKey, laborFee)
            return { ok = true, message = msg }
        end
    end
    return { ok = false, message = 'Falha no reparo.' }
end)
