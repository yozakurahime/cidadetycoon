local function DebugLog(text, ...)
    print(string.format("^2[Tycoon:Server:Market]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- DATABASE REFORMS (Guardian Requirement)
-- ==========================================
CreateThread(function()
    pcall(function()
        local columns = MySQL.query.await("SHOW COLUMNS FROM player_vehicles")
        local existingCols = {}
        for _, col in ipairs(columns) do existingCols[col.Field] = true end
        
        if not existingCols['insurance_tier'] then 
            MySQL.update.await("ALTER TABLE player_vehicles ADD COLUMN insurance_tier INT DEFAULT 0") 
        end
        if not existingCols['in_debt_since'] then 
            MySQL.update.await("ALTER TABLE player_vehicles ADD COLUMN in_debt_since TIMESTAMP NULL DEFAULT NULL") 
        end
    end)
    
    -- CREATE FINANCING TABLE (Unified)
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_financings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            vehicle_model VARCHAR(50) NOT NULL,
            plate VARCHAR(15) NOT NULL,
            total_price BIGINT NOT NULL,
            amount_paid BIGINT DEFAULT 0,
            installments_paid INT DEFAULT 0,
            total_installments INT NOT NULL,
            installment_amount BIGINT NOT NULL,
            last_payment TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_active TINYINT(1) DEFAULT 1,
            INDEX (citizenid),
            INDEX (plate)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- ==========================================
-- MARKET & FINANCING CORE
-- ==========================================

local function getDefaultVehicleProps(model, plate)
    return json.encode({ plate = plate, engineHealth = 1000.0, bodyHealth = 1000.0, fuelLevel = 100.0, model = model })
end

-- 1. Vista Purchase
lib.callback.register('cidade_tycoon_market:server:purchaseVehicle', function(source, model)
    local vehicleData = exports.cidade_tycoon_core:GetVehicleData(model)
    if not vehicleData then return { ok = false, message = 'Veículo não disponível.' } end

    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = profile.citizenid

    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < vehicleData.price then
        return { ok = false, message = 'Saldo insuficiente.' }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', vehicleData.price, 'tycoon-vehicle-purchase') then
        local plate = exports.cidade_tycoon_core:NormalizePlate("TYC" .. math.random(100, 999))
        
        MySQL.insert.await([[
            INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, type)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], { player.PlayerData.license, citizenId, model, joaat(model), getDefaultVehicleProps(model, plate), plate, 'public', 1, 'car' })

        exports.cidade_tycoon_core:LogTransaction(source, vehicleData.price, 'expense', 'purchase', 'Compra à vista: ' .. vehicleData.label)
        return { ok = true, message = 'Veículo adquirido com sucesso!', plate = plate }
    end
    return { ok = false, message = 'Erro no pagamento.' }
end)

-- 2. Financing (Manual Payments)
lib.callback.register('cidade_tycoon_market:server:purchaseVehicleFinanced', function(source, model, installments)
    local vehicleData = exports.cidade_tycoon_core:GetVehicleData(model)
    if not vehicleData or not vehicleData.financing then return { ok = false, message = 'Não aceita financiamento.' } end

    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = profile.citizenid

    local totalPrice = math.floor(vehicleData.price * 1.15)
    local downPayment = math.floor(totalPrice * 0.20)
    
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < downPayment then
        return { ok = false, message = ('Entrada insuficiente ($%d).'):format(downPayment) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', downPayment, 'tycoon-vehicle-financing-down') then
        local plate = exports.cidade_tycoon_core:NormalizePlate("FIN" .. math.random(100, 999))
        local installmentAmount = math.ceil((totalPrice - downPayment) / installments)

        -- Register in DB
        MySQL.insert.await([[
            INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, type)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], { player.PlayerData.license, citizenId, model, joaat(model), getDefaultVehicleProps(model, plate), plate, 'public', 1, 'car' })

        MySQL.insert.await([[
            INSERT INTO tycoon_financings (citizenid, vehicle_model, plate, total_price, amount_paid, total_installments, installment_amount)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], { citizenId, model, plate, totalPrice, downPayment, installments, installmentAmount })

        exports.cidade_tycoon_core:LogTransaction(source, downPayment, 'expense', 'purchase', 'Entrada financiamento: ' .. model)
        return { ok = true, message = 'Financiamento aprovado! Pague as parcelas no Tablet.', plate = plate }
    end
    return { ok = false, message = 'Erro no processamento.' }
end)

-- ==========================================
-- INSURANCE & MAINTENANCE RECOVERY
-- ==========================================

lib.callback.register('cidade_tycoon_market:server:purchaseInsurance', function(source, plate, tier)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    
    local vehicle = MySQL.single.await('SELECT vehicle FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, citizenId })
    if not vehicle then return { ok = false, message = 'Veículo não encontrado.' } end

    local vehData = exports.cidade_tycoon_core:GetVehicleData(vehicle.vehicle)
    local price = vehData and vehData.price or 25000
    
    -- Tier Pricing: Bronze 2%, Silver 5%, Gold 10%
    local multipliers = { [1] = 0.02, [2] = 0.05, [3] = 0.10 }
    local cost = math.floor(price * (multipliers[tier] or 0.02))

    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < cost then
        return { ok = false, message = 'Saldo insuficiente.' }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', cost, 'tycoon-vehicle-insurance') then
        -- Additive Insurance Logic (Rule #3)
        MySQL.update.await([[
            UPDATE player_vehicles 
            SET insurance_expiry = DATE_ADD(COALESCE(insurance_expiry, NOW()), INTERVAL 7 DAY),
                insurance_tier = ?
            WHERE plate = ?
        ]], { tier, plate })

        exports.cidade_tycoon_core:LogTransaction(source, cost, 'expense', 'insurance', ('Seguro Tier %d: %s'):format(tier, plate))
        return { ok = true, message = 'Seguro ativado/estendido por 7 dias!' }
    end
end)

-- ==========================================
-- ENFORCEMENT & SEIZURE (Rule #1 & #4)
-- ==========================================

CreateThread(function()
    while true do
        Wait(3600000) -- Check every hour
        
        -- 1. Lock vehicles with > 3 days delay
        MySQL.update.await([[
            UPDATE player_vehicles pv
            JOIN tycoon_financings f ON pv.plate COLLATE utf8mb4_unicode_ci = f.plate COLLATE utf8mb4_unicode_ci
            SET pv.state = 3, pv.in_debt_since = NOW()
            WHERE f.is_active = 1 
            AND f.last_payment < DATE_SUB(NOW(), INTERVAL 3 DAY)
            AND pv.state != 3
        ]])

        -- 2. REAL SEIZURE (Permanent Deletion) > 7 days delay
        local vehiclesToSeize = MySQL.query.await([[
            SELECT plate FROM tycoon_financings 
            WHERE is_active = 1 
            AND last_payment < DATE_SUB(NOW(), INTERVAL 7 DAY)
        ]])

        for _, v in ipairs(vehiclesToSeize) do
            local plate = v.plate
            DebugLog("^1APREENSÃO:^7 Veículo %s deletado por falta de pagamento.", plate)
            
            -- Atomic Transaction Cleanup
            MySQL.transaction.await({
                'DELETE FROM player_vehicles WHERE plate = ?',
                'DELETE FROM tycoon_vehicle_status WHERE plate = ?',
                'DELETE FROM tycoon_financings WHERE plate = ?'
            }, { plate, plate, plate })
            
            -- Trunk cleanup (Requires ox_inventory check)
            pcall(function() exports.ox_inventory:ClearInventory('trunk-' .. plate) end)
        end
    end
end)

-- Manual Payment Callback
lib.callback.register('cidade_tycoon_market:server:payInstallment', function(source, financingId)
    local f = MySQL.single.await('SELECT * FROM tycoon_financings WHERE id = ? AND is_active = 1', { financingId })
    if not f then return { ok = false, message = 'Contrato não encontrado.' } end

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < f.installment_amount then
        return { ok = false, message = 'Saldo insuficiente.' }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', f.installment_amount, 'tycoon-financing-payment') then
        local finished = (f.installments_paid + 1 >= f.total_installments)
        
        MySQL.update.await([[
            UPDATE tycoon_financings SET 
                installments_paid = installments_paid + 1,
                amount_paid = amount_paid + ?,
                last_payment = NOW(),
                is_active = ?
            WHERE id = ?
        ]], { f.installment_amount, finished and 0 or 1, financingId })

        -- Unlock vehicle
        MySQL.update.await("UPDATE player_vehicles SET state = 1, in_debt_since = NULL WHERE plate = ?", { f.plate })

        return { ok = true, message = finished and 'Veículo quitado!' or 'Parcela paga. Veículo liberado.' }
    end
end)
