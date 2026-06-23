local sharedConfig = require 'config/shared'

-- Initialize Pending Customs Orders Table
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS tycoon_customs_orders (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            plate VARCHAR(20) NOT NULL,
            client_citizenid VARCHAR(50) NOT NULL,
            mechanic_citizenid VARCHAR(50) NOT NULL,
            mechanic_name VARCHAR(100) NOT NULL,
            subtotal BIGINT NOT NULL,
            fee BIGINT NOT NULL,
            total BIGINT NOT NULL,
            items TEXT NOT NULL,
            mods LONGTEXT NOT NULL,
            status VARCHAR(20) DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ]])
end)

local function savePendingOrder(plate, clientCitizenId, mechanicCitizenId, mechanicName, subtotal, fee, total, items, mods)
    local itemsJson = json.encode(items)
    local modsJson = json.encode(mods)

    local success, err = pcall(function()
        return MySQL.insert.await([[
            INSERT INTO tycoon_customs_orders (plate, client_citizenid, mechanic_citizenid, mechanic_name, subtotal, fee, total, items, mods, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
        ]], { plate, clientCitizenId, mechanicCitizenId, mechanicName, subtotal, fee, total, itemsJson, modsJson })
    end)

    if not success then
        print("^1[Tycoon:Server:Customs] Error inserting pending order:^7", err)
    end
    return success
end

local function DebugLog(text, ...)
    print(string.format("^5[Tycoon:Server:Customs]^7 %s", string.format(text, ...)))
end

local function normalizePlate(plate)
    return exports.cidade_tycoon_core:NormalizePlate(plate)
end

-- Helper: Server-side Proximity Check
local function isNearAnyWorkshop(source)
    local pCoords = GetEntityCoords(GetPlayerPed(source))

    local customSpots = GlobalState['tycoon:customs_spots']
    if customSpots and #customSpots > 0 then
        for _, coords in ipairs(customSpots) do
            local spot = vector3(coords.x, coords.y, coords.z)
            if #(pCoords - spot) < sharedConfig.WorkshopDistance + 5.0 then
                return true
            end
        end
    else
        for _, coords in ipairs(sharedConfig.Workshops) do
            if #(pCoords - coords) < sharedConfig.WorkshopDistance + 5.0 then
                return true
            end
        end
    end
    return false
end

-- Persist properties to database
local function saveVehicleProperties(plate, props)
    if not plate or not props then return false end
    local normalizedPlate = normalizePlate(plate)
    props.plate = props.plate or normalizedPlate

    local success, affected = pcall(function()
        return MySQL.update.await([[
            UPDATE player_vehicles
            SET mods = ?
            WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
        ]], {
            json.encode(props),
            plate,
            normalizedPlate
        })
    end)
    return success and affected and affected > 0
end

local function getCartItemPrice(mod)
    if type(mod) == 'string' and (mod:sub(1, 7) == 'visual_' or mod:sub(1, 6) == 'extra_') then
        return sharedConfig.Prices.visualMod or 0
    end

    return sharedConfig.Prices[mod] or 0
end

-- CHECKOUT CALLBACK (Shopping Cart)
lib.callback.register('cidade_tycoon_customs:server:checkout', function(source, plate, finalProps, cart)
    local src = source
    if not exports.cidade_tycoon_core:CheckRateLimit(src, 'customs_checkout', 5000) then
        return { ok = false, message = 'Aguarde antes de realizar outra transacao.' }
    end
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)

    -- 1. Security: Proximity Check
    if not isNearAnyWorkshop(src) then
        return { ok = false, message = 'Voce esta muito longe da oficina para processar o pagamento.' }
    end

    -- 2. Security: Ownership Verification
    local normalizedPlate = normalizePlate(plate)
    local vehicleOwner = MySQL.scalar.await([[
        SELECT citizenid
        FROM player_vehicles
        WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
        LIMIT 1
    ]], { plate, normalizedPlate })
    local isAuthorized = (vehicleOwner == citizenId)

    if not isAuthorized then
        -- Check if it's a company vehicle and if player has permissions
        local profile = exports.cidade_tycoon_core:GetPlayerProfile(src)
        if profile and profile.hubId then
            isAuthorized = true
        end
    end

    -- Mechanics are always authorized to customize vehicles in their shop
    local playerJobName = player and player.PlayerData and player.PlayerData.job and player.PlayerData.job.name
    if not isAuthorized and playerJobName == 'mechanic' then
        isAuthorized = true
    end

    if not isAuthorized then
        return { ok = false, message = 'Voce nao tem permissao para customizar este veiculo.' }
    end

    -- 3. Calculate Total from Server Config (Ignore Client Price)
    local totalCost = 0
    local itemsApplied = 0
    for mod, active in pairs(cart) do
        if active then
            totalCost = totalCost + getCartItemPrice(mod)
            itemsApplied = itemsApplied + 1
        end
    end

    if totalCost == 0 then return { ok = false, message = 'Carrinho vazio.' } end

    -- 4. Process Payment
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < totalCost then
        return { ok = false, message = ('Saldo insuficiente ($%d).'):format(totalCost) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', totalCost, 'tycoon-vehicle-customization') then
        -- 5. Final Persist
        if saveVehicleProperties(plate, finalProps) then
            TriggerClientEvent('cidade_tycoon_customs:client:applyPaidMods', -1, plate, finalProps)
            exports.cidade_tycoon_core:LogTransaction(src, totalCost, 'expense', 'customization', ('Customizacao de frota (%d itens): %s'):format(itemsApplied, plate))
            DebugLog("Veiculo %s customizado por %s por $%d", plate, citizenId, totalCost)
            return { ok = true, message = ('Pagamento de $%d processado. Veiculo salvo!'):format(totalCost) }
        else
            -- Refund on critical DB fail
            exports.cidade_tycoon_core:AddMoney(player, 'bank', totalCost, 'tycoon-customs-refund')
            return { ok = false, message = 'Falha critica ao salvar no banco de dados. Reembolsado.' }
        end
    end

    return { ok = false, message = 'Falha no processamento financeiro.' }
end)

-- BILL CLIENT CALLBACK (Invoice)
lib.callback.register('cidade_tycoon_customs:server:billClient', function(source, targetId, plate, finalProps, cart, fee)
    local src = source
    if not exports.cidade_tycoon_core:CheckRateLimit(src, 'customs_bill', 5000) then
        return { ok = false, message = 'Aguarde antes de emitir outra cobranca.' }
    end
    local mechanicPlayer = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    local mechanicJobName = mechanicPlayer and mechanicPlayer.PlayerData and mechanicPlayer.PlayerData.job and mechanicPlayer.PlayerData.job.name
    if mechanicJobName ~= 'mechanic' then
        return { ok = false, message = 'Apenas mecanicos podem emitir cobrancas para clientes.' }
    end

    local targetPlayer = exports.cidade_tycoon_core:GetFrameworkPlayer(tonumber(targetId))
    if not targetPlayer then
        return { ok = false, message = 'Cliente offline ou ID de passaporte invalido.' }
    end

    local targetSrc = targetPlayer.PlayerData.source
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetSrc))) > 15.0 then
        return { ok = false, message = 'O cliente esta muito longe de voce para assinar a ordem de servico.' }
    end

    -- Calculate total
    local subtotal = 0
    local itemsApplied = {}
    for mod, active in pairs(cart) do
        if active then
            local itemPrice = getCartItemPrice(mod)
            subtotal = subtotal + itemPrice
            local itemLabel = mod
            if mod == 'primaryColor' then itemLabel = 'Pintura Primaria'
            elseif mod == 'secondaryColor' then itemLabel = 'Pintura Secundaria'
            elseif mod == 'pearlescentColor' then itemLabel = 'Perolado'
            elseif mod == 'wheelColor' then itemLabel = 'Cor das Rodas'
            elseif mod == 'wheels' then itemLabel = 'Rodas Novas'
            elseif mod == 'neonToggle' then itemLabel = 'Kit Neon'
            elseif mod == 'neonColor' then itemLabel = 'Cor Neon RGB'
            elseif mod == 'xenonColor' then itemLabel = 'Farois Xenon'
            elseif mod == 'windowTint' then itemLabel = 'Pelicula Vidros'
            elseif mod == 'wash' then itemLabel = 'Lavagem Profissional'
            elseif mod:sub(1, 7) == 'visual_' then itemLabel = 'Peca Visual'
            elseif mod:sub(1, 6) == 'extra_' then itemLabel = 'Extra Visual'
            end
            table.insert(itemsApplied, itemLabel .. ' ($' .. itemPrice .. ')')
        end
    end

    if subtotal == 0 then return { ok = false, message = 'Carrinho de customizacao vazio.' } end

    local feeVal = tonumber(fee) or 0
    local total = subtotal + feeVal

    -- Prompt the client for approval
    local accept = lib.callback.await('cidade_tycoon_customs:client:requestPaymentApproval', targetSrc, subtotal, feeVal, total, plate, itemsApplied)

    local clientCitizenId = exports.cidade_tycoon_core:GetCitizenId(targetPlayer)
    local mechanicCitizenId = exports.cidade_tycoon_core:GetCitizenId(mechanicPlayer)
    local mechanicName = mechanicPlayer.PlayerData.charinfo.firstname .. ' ' .. mechanicPlayer.PlayerData.charinfo.lastname

    if not accept then
        -- Save the work order as pending
        savePendingOrder(plate, clientCitizenId, mechanicCitizenId, mechanicName, subtotal, feeVal, total, itemsApplied, finalProps)

        TriggerClientEvent('ox_lib:notify', targetSrc, {
            title = 'Ordem de Servico',
            description = 'Voce recusou a OS imediata. Ela foi salva nos seus Servicos Pendentes no Tablet.',
            type = 'warning'
        })
        return { ok = true, message = 'O cliente recusou ou guardou a cobranca. A ordem foi salva como PENDENTE.' }
    end

    -- Check client balance
    if exports.cidade_tycoon_core:GetMoneyBalance(targetPlayer, 'bank') < total then
        -- Save the work order as pending
        savePendingOrder(plate, clientCitizenId, mechanicCitizenId, mechanicName, subtotal, feeVal, total, itemsApplied, finalProps)

        TriggerClientEvent('ox_lib:notify', targetSrc, {
            title = 'Ordem de Servico',
            description = 'Saldo insuficiente no banco. A ordem de servico foi salva nos seus Servicos Pendentes.',
            type = 'error'
        })
        return { ok = true, message = 'O cliente aceitou, mas nao tinha saldo suficiente. A ordem foi salva como PENDENTE.' }
    end

    -- Deduct money and apply mods
    if exports.cidade_tycoon_core:RemoveMoney(targetPlayer, 'bank', total, 'tycoon-vehicle-customization-bill') then
        if saveVehicleProperties(plate, finalProps) then
            TriggerClientEvent('cidade_tycoon_customs:client:applyPaidMods', -1, plate, finalProps)
            exports.cidade_tycoon_core:LogTransaction(targetSrc, total, 'expense', 'customization', ('Pagamento OS Customizacao: %s'):format(plate))

            -- Distribute Payment: Labor fee to mechanic, parts cost to society_mechanic
            if feeVal > 0 then
                exports.cidade_tycoon_core:AddMoney(mechanicPlayer, 'bank', feeVal, 'tycoon-mechanic-labor-fee')
                exports.cidade_tycoon_core:NotifyPlayer(src, ('Voce recebeu R$%d pela mao de obra do veiculo %s.'):format(feeVal, plate), 'success')
            end

            if subtotal > 0 then
                exports.okokBanking:AddSocietyMoney('society_mechanic', subtotal)
            end

            -- Save as PAID for history/accounting
            pcall(function()
                MySQL.insert.await([[
                    INSERT INTO tycoon_customs_orders (plate, client_citizenid, mechanic_citizenid, mechanic_name, subtotal, fee, total, items, mods, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'paid')
                ]], { plate, clientCitizenId, mechanicCitizenId, mechanicName, subtotal, feeVal, total, json.encode(itemsApplied), json.encode(finalProps) })
            end)

            local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname

            -- Broadcast work order published event
            TriggerEvent('cidade_tycoon_customs:server:createWorkOrder', {
                plate = plate,
                client = targetName .. ' (ID ' .. targetId .. ')',
                mechanic = mechanicName,
                total = total,
                items = itemsApplied
            })

            return { ok = true, message = ('Cobranca paga! R$%d cobrados de %s.'):format(total, targetName) }
        else
            -- Refund client
            exports.cidade_tycoon_core:AddMoney(targetPlayer, 'bank', total, 'tycoon-customs-refund')
            return { ok = false, message = 'Falha ao salvar customizacoes no banco de dados. Reembolsado.' }
        end
    end

    return { ok = false, message = 'Erro desconhecido ao processar pagamento do cliente.' }
end)

-- NET EVENT: Broadcast Work Order
RegisterNetEvent('cidade_tycoon_customs:server:createWorkOrder', function(data)
    local src = source
    local mechanicName = data.mechanic
    if not mechanicName and src > 0 then
        local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
        if player then
            mechanicName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        end
    end
    mechanicName = mechanicName or "Mecanico"

    local itemsStr = ""
    for _, it in ipairs(data.items) do
        itemsStr = itemsStr .. "<div style='padding-left: 10px; color: rgba(239, 246, 255, 0.85); font-size: 0.95em;'>" .. it .. "</div>"
    end

    -- Format a premium chat message with custom template matching HUD/Tablet aesthetics
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="margin: 10px 0; padding: 16px; background: linear-gradient(135deg, rgba(20, 25, 35, 0.85), rgba(10, 15, 20, 0.95)); border: 1px solid rgba(90, 200, 250, 0.3); border-radius: 12px; box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4); backdrop-filter: blur(10px); color: #f7fbff; font-family: \'Outfit\', sans-serif;"><div style="display: flex; align-items: center; gap: 8px; border-bottom: 1px solid rgba(229, 241, 255, 0.15); padding-bottom: 8px; margin-bottom: 10px;"><span style="color: #5ac8fa; font-size: 1.2em; font-weight: 800; letter-spacing: 1px;">Yi ORDEM DE SERVIAO</span><span style="background: #5ac8fa; color: #000; font-size: 0.75em; font-weight: 800; padding: 2px 6px; border-radius: 4px; margin-left: auto;">{0}</span></div><div style="display: flex; flex-direction: column; gap: 4px; margin-bottom: 12px; font-size: 0.9em; color: rgba(239, 246, 255, 0.75);"><div>Y <b>Cliente:</b> <span style="color: #fff;">{1}</span></div><div>Y <b>Mecanico:</b> <span style="color: #fff;">{2}</span></div></div><div style="font-weight: 600; font-size: 0.95em; color: #5ac8fa; margin-bottom: 6px;">Servicos Executados:</div><div style="display: flex; flex-direction: column; gap: 3px; margin-bottom: 12px;">{3}</div><div style="display: flex; align-items: center; border-top: 1px solid rgba(229, 241, 255, 0.15); padding-top: 8px; font-weight: bold; font-size: 1.1em;"><span style="color: rgba(239, 246, 255, 0.8);">Valor Cobrado:</span><span style="color: #34c759; margin-left: auto;">${4}</span></div></div>',
        args = {
            data.plate,
            data.client or "Nao Informado",
            mechanicName,
            itemsStr,
            data.total
        }
    })
end)
