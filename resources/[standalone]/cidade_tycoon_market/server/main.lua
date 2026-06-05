local function DebugLog(text, ...)
    print(string.format("^2[Tycoon:Server:Market]^7 %s", string.format(text, ...)))
end

-- Profile helper using Core Exports and State Bags
local function getProfile(source)
    local stateProfile = Player(source).state.tycoonProfile
    if stateProfile then return stateProfile end
    return exports.cidade_tycoon_core:GetPlayerProfile(source)
end

-- Market Purchase Logic
lib.callback.register('cidade_tycoon_market:server:purchaseVehicle', function(source, model)
    local vehicleData = exports.cidade_tycoon_core:GetVehicleData(model)
    if not vehicleData then
        return { ok = false, message = 'Veiculo nao disponivel para venda.' }
    end

    local profile = getProfile(source)
    if not profile then return { ok = false, message = 'Perfil nao encontrado.' } end

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = profile.citizenid
    
    -- License Validation
    if vehicleData.requiredLicense and not profile.licenses[vehicleData.requiredLicense] then
        return { ok = false, message = ('Voce nao possui a habilitacao necessaria (%s).'):format(vehicleData.requiredLicense) }
    end

    local price = vehicleData.price
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < price then
        return { ok = false, message = ('Saldo insuficiente. Preco: $%d'):format(price) }
    end

    -- Process payment via Core
    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', price, 'tycoon-vehicle-purchase') then
        -- Register vehicle in Qbox/Player Garages
        local plate = exports.cidade_tycoon_core:NormalizePlate("TYC" .. math.random(100, 999))
        
        -- Use qbx_vehicles or direct MySQL insert if preferred
        -- Using direct insert for absolute control in this prototype
        MySQL.insert.await([[
            INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], { player.PlayerData.license, citizenId, model, joaat(model), json.encode({ plate = plate }), plate, 'motelgarage', 1 })

        -- Log Transaction
        exports.cidade_tycoon_core:LogTransaction(source, price, 'expense', 'purchase', ('Compra de veiculo: %s'):format(vehicleData.label))

        DebugLog("Jogador %s comprou %s (Placa: %s)", citizenId, model, plate)
        
        return { 
            ok = true, 
            message = ('Voce adquiriu um %s! Ele esta na garagem do Motel.'):format(vehicleData.label),
            plate = plate
        }
    end

    return { ok = false, message = 'Falha ao processar pagamento.' }
end)

-- Financing Logic
lib.callback.register('cidade_tycoon_market:server:purchaseVehicleFinanced', function(source, model, installments)
    local vehicleData = exports.cidade_tycoon_core:GetVehicleData(model)
    if not vehicleData or not vehicleData.financing then
        return { ok = false, message = 'Este veiculo nao aceita financiamento.' }
    end

    local profile = getProfile(source)
    if not profile then return { ok = false, message = 'Perfil nao encontrado.' } end

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = profile.citizenid

    local totalPrice = math.floor(vehicleData.price * 1.15) -- 15% interest for financing
    local downPayment = math.floor(totalPrice * 0.20) -- 20% down payment
    
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < downPayment then
        return { ok = false, message = ('Saldo insuficiente para a entrada ($%d).'):format(downPayment) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', downPayment, 'tycoon-vehicle-financing-down') then
        local plate = exports.cidade_tycoon_core:NormalizePlate("TYC" .. math.random(100, 999))
        local remainingBalance = totalPrice - downPayment
        local installmentAmount = math.ceil(remainingBalance / installments)

        -- Register vehicle
        MySQL.insert.await([[
            INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], { player.PlayerData.license, citizenId, model, joaat(model), json.encode({ plate = plate }), plate, 'motelgarage', 1 })

        -- Register financing
        MySQL.insert.await([[
            INSERT INTO tycoon_financings (citizenid, vehicle_model, plate, total_price, amount_paid, installments_paid, total_installments, installment_amount)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], { citizenId, model, plate, totalPrice, downPayment, 0, installments, installmentAmount })

        exports.cidade_tycoon_core:LogTransaction(source, downPayment, 'expense', 'purchase', ('Entrada financiamento: %s'):format(vehicleData.label))

        return { 
            ok = true, 
            message = ('Financiamento aprovado! O %s foi entregue na garagem. %d parcelas de $%d.'):format(vehicleData.label, installments, installmentAmount),
            plate = plate
        }
    end

    return { ok = false, message = 'Falha no processamento.' }
end)

-- Process Recurring Payments (Cron-like)
local function processFinancingPayments()
    local financings = MySQL.query.await('SELECT * FROM tycoon_financings WHERE is_active = 1')
    for _, f in ipairs(financings) do
        local player = exports.qbx_core:GetPlayerByCitizenId(f.citizenid)
        if player then
            if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') >= f.installment_amount then
                if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', f.installment_amount, 'tycoon-financing-installment') then
                    local newInstallmentsPaid = f.installments_paid + 1
                    local newAmountPaid = f.amount_paid + f.installment_amount
                    local isActive = newInstallmentsPaid < f.total_installments

                    MySQL.update.await([[
                        UPDATE tycoon_financings 
                        SET installments_paid = ?, amount_paid = ?, is_active = ?, last_payment = CURRENT_TIMESTAMP
                        WHERE id = ?
                    ]], { newInstallmentsPaid, newAmountPaid, isActive and 1 or 0, f.id })

                    TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
                        title = 'Banco Tycoon',
                        description = ('Parcela de financiamento paga: $%d (%d/%d)'):format(f.installment_amount, newInstallmentsPaid, f.total_installments),
                        type = 'inform'
                    })
                end
            else
                TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
                    title = 'Banco Tycoon',
                    description = 'AVISO: Saldo insuficiente para pagar parcela do veículo! Risco de apreensão.',
                    type = 'error'
                })
                -- TODO: Implement vehicle seizure logic if multiple payments are missed
            end
        end
    end
end

-- Run every 12 hours (real-time)
CreateThread(function()
    while true do
        processFinancingPayments()
        Wait(12 * 60 * 60 * 1000)
    end
end)

local function getPlayerFinancings(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    return MySQL.query.await('SELECT * FROM tycoon_financings WHERE citizenid = ? AND is_active = 1', { citizenId })
end

local function checkInsurance(plate)
    local row = MySQL.single.await('SELECT insurance_expiry FROM player_vehicles WHERE plate = ?', { plate })
    if not row or not row.insurance_expiry then return false end
    
    local expiryTime = math.floor(row.insurance_expiry / 1000)
    return expiryTime > os.time()
end

exports('GetPlayerFinancings', getPlayerFinancings)
exports('CheckInsurance', checkInsurance)

lib.callback.register('cidade_tycoon_market:server:getPlayerFinancings', function(source)
    return getPlayerFinancings(source)
end)

-- Insurance Logic
lib.callback.register('cidade_tycoon_market:server:purchaseInsurance', function(source, plate)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if not player then return { ok = false, message = 'Erro ao identificar jogador.' } end

    local vehicle = MySQL.single.await('SELECT vehicle FROM player_vehicles WHERE plate = ? AND citizenid = ?', { 
        plate, 
        exports.cidade_tycoon_core:GetCitizenId(player) 
    })
    if not vehicle then return { ok = false, message = 'Veiculo nao encontrado na sua garagem.' } end

    local vehData = exports.cidade_tycoon_core:GetVehicleData(vehicle.vehicle)
    local insurancePrice = math.max(500, math.floor((vehData and vehData.price or 20000) * 0.02)) -- 2% of vehicle price
    
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < insurancePrice then
        return { ok = false, message = ('Saldo insuficiente ($%d necessário).'):format(insurancePrice) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', insurancePrice, 'tycoon-vehicle-insurance') then
        local expiry = os.time() + (7 * 24 * 60 * 60) -- 7 days insurance
        
        MySQL.update.await('UPDATE player_vehicles SET insurance_expiry = FROM_UNIXTIME(?) WHERE plate = ?', { expiry, plate })
        
        exports.cidade_tycoon_core:LogTransaction(source, insurancePrice, 'expense', 'insurance', 'Seguro de Frota: ' .. plate)
        
        return { ok = true, message = ('Seguro ativado para a placa %s por 7 dias!'):format(plate) }
    end

    return { ok = false, message = 'Falha ao processar pagamento.' }
end)

-- Update GetRecoveryCost logic in Core (Indirectly by checking DB)
lib.callback.register('cidade_tycoon_market:server:checkInsurance', function(source, plate)
    local row = MySQL.single.await('SELECT insurance_expiry FROM player_vehicles WHERE plate = ?', { plate })
    if not row or not row.insurance_expiry then return false end
    
    local expiryTime = math.floor(row.insurance_expiry / 1000) -- Handle MariaDB/MySQL timestamp
    return expiryTime > os.time()
end)


