local function DebugLog(text, ...)
    print(string.format("^6[Tycoon:Server:AutoParts]^7 %s", string.format(text, ...)))
end

-- Market Shop (Parts)
lib.callback.register('cidade_tycoon_autoparts:server:purchasePart', function(source, itemName, amount)
    local partData = exports.cidade_tycoon_core:GetPartData(itemName)
    if not partData then return { ok = false, message = 'Peça invalida.' } end

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local totalPrice = partData.price * amount

    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < totalPrice then
        return { ok = false, message = ('Saldo insuficiente para %d unidades.'):format(amount) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', totalPrice, 'tycoon-autoparts-purchase') then
        if exports.ox_inventory:AddItem(source, itemName, amount) then
            exports.cidade_tycoon_core:LogTransaction(source, totalPrice, 'expense', 'purchase', 'Compra de Auto Peças: ' .. partData.label)
            DebugLog("Jogador %s comprou %d x %s", player.PlayerData.citizenid, amount, itemName)
            return { ok = true, message = ('Voce adquiriu %d x %s!'):format(amount, partData.label) }
        else
            -- Refund if inventory fails
            player.Functions.AddMoney('bank', totalPrice, 'tycoon-autoparts-refund')
            return { ok = false, message = 'Inventario cheio.' }
        end
    end

    return { ok = false, message = 'Falha no pagamento.' }
end)

-- Recycling Logic (Scrap -> Warehouse Materials)
lib.callback.register('cidade_tycoon_autoparts:server:recycleScrap', function(source, scrapItem)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if not player then return { ok = false, message = 'Erro de identificação.' } end

    local company = exports.cidade_tycoon_logistics:GetCompanyData(source)
    if not company then return { ok = false, message = 'Somente donos de empresa podem reciclar sucata para o galpão.' } end

    local count = exports.ox_inventory:GetItemCount(source, scrapItem)
    if count < 1 then return { ok = false, message = 'Você não possui sucata para reciclar.' } end

    -- Remove Scrap from Inventory
    if exports.ox_inventory:RemoveItem(source, scrapItem, 1) then
        local rewardMaterial = (scrapItem == 'electronic_scrap') and 'raw_electronics' or 'raw_metal'
        local rewardQty = 5

        -- Add to Warehouse Inventory (Production Module Table)
        local success = MySQL.update.await([[
            INSERT INTO tycoon_warehouse_inventory (company_id, item_key, amount)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount)
        ]], { company.id, rewardMaterial, rewardQty })

        if success then
            DebugLog("Empresa %d reciclou %s em %d unidades de %s", company.id, scrapItem, rewardQty, rewardMaterial)
            return { ok = true, message = ('Sucata reciclada! +%d unidades de %s adicionadas ao estoque.'):format(rewardQty, rewardMaterial) }
        end
    end

    return { ok = false, message = 'Falha ao processar reciclagem.' }
end)

