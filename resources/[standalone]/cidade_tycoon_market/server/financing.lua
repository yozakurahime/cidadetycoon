local function DebugLog(text, ...)
    print(string.format("^2[Tycoon:Server:Financing]^7 %s", string.format(text, ...)))
end

-- Financing Configuration
local FinancingConfig = {
    downPaymentPercent = 0.20, -- 20% de entrada
    installments = 12, -- 12 parcelas
    interestRate = 1.15, -- 15% de juros no total
}

-- Create Financing Contract
lib.callback.register('cidade_tycoon_market:server:startFinancing', function(source, model)
    local vehicleData = exports.cidade_tycoon_core:GetVehicleData(model)
    if not vehicleData then return { ok = false, message = 'Veiculo invalido.' } end

    -- License Validation
    if vehicleData.requiredLicense and not exports.cidade_tycoon_core:HasLicense(source, vehicleData.requiredLicense) then
        return { ok = false, message = ('Voce nao possui a habilitacao necessaria (%s).'):format(vehicleData.requiredLicense) }
    end

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    
    local totalPrice = math.floor(vehicleData.price * FinancingConfig.interestRate)
    local downPayment = math.floor(vehicleData.price * FinancingConfig.downPaymentPercent)
    local remainingDebt = totalPrice - downPayment
    local installmentAmount = math.floor(remainingDebt / FinancingConfig.installments)

    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < downPayment then
        return { ok = false, message = ('Entrada insuficiente. Requer: $%d'):format(downPayment) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', downPayment, 'tycoon-vehicle-financing-downpayment') then
        local plate = exports.cidade_tycoon_core:NormalizePlate("FIN" .. math.random(100, 999))
        
        -- Insert Financing Contract
        MySQL.insert.await([[
            INSERT INTO tycoon_financings (citizenid, vehicle_model, plate, total_price, amount_paid, installments_paid, total_installments, installment_amount)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], { citizenId, model, plate, totalPrice, downPayment, 0, FinancingConfig.installments, installmentAmount })

        -- Register Vehicle
        MySQL.insert.await([[
            INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], { player.PlayerData.license, citizenId, model, joaat(model), json.encode({ plate = plate }), plate, 'motelgarage', 1 })

        DebugLog("Jogador %s financiou %s (Placa: %s). Entrada: $%d", citizenId, model, plate, downPayment)
        
        return { 
            ok = true, 
            message = ('Financiamento aprovado! %s parcelas de $%d. Veiculo na garagem do Motel.'):format(FinancingConfig.installments, installmentAmount),
            plate = plate
        }
    end

    return { ok = false, message = 'Falha ao processar entrada.' }
end)

local function getPlayerFinancingsForSource(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return {} end

    return MySQL.query.await('SELECT * FROM tycoon_financings WHERE citizenid = ? AND is_active = 1', { citizenId })
end

-- Get Active Financings for Player
lib.callback.register('cidade_tycoon_market:server:getPlayerFinancings', getPlayerFinancingsForSource)
exports('GetPlayerFinancingsForSource', getPlayerFinancingsForSource)

-- Pay Installment
lib.callback.register('cidade_tycoon_market:server:payInstallment', function(source, financingId)
    local financing = MySQL.single.await('SELECT * FROM tycoon_financings WHERE id = ? AND is_active = 1', { financingId })
    if not financing then return { ok = false, message = 'Financiamento nao encontrado.' } end

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < financing.installment_amount then
        return { ok = false, message = 'Saldo insuficiente para a parcela.' }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', financing.installment_amount, 'tycoon-vehicle-installment') then
        local newInstallmentsPaid = financing.installments_paid + 1
        local newAmountPaid = financing.amount_paid + financing.installment_amount
        local isActive = newInstallmentsPaid < financing.total_installments and 1 or 0

        MySQL.update.await([[
            UPDATE tycoon_financings 
            SET installments_paid = ?, amount_paid = ?, is_active = ?, last_payment = CURRENT_TIMESTAMP
            WHERE id = ?
        ]], { newInstallmentsPaid, newAmountPaid, isActive, financingId })

        -- Log Transaction
        exports.cidade_tycoon_core:LogTransaction(source, financing.installment_amount, 'expense', 'installment', ('Parcela veiculo: %s'):format(financing.vehicle_model))

        if isActive == 0 then
            return { ok = true, message = 'Ultima parcela paga! O veiculo agora e totalmente seu.' }
        end

        return { ok = true, message = ('Parcela %d/%d paga com sucesso.'):format(newInstallmentsPaid, financing.total_installments) }
    end

    return { ok = false, message = 'Falha no pagamento.' }
end)
