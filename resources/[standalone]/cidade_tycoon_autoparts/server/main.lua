local activeTransactions = {}

local function DebugLog(text, ...)
    print(string.format("^6[Tycoon:Server:AutoParts]^7 %s", string.format(text, ...)))
end

-- Helper: Check if player is near any warehouse
local function isNearAnyWarehouse(source)
    local pCoords = GetEntityCoords(GetPlayerPed(source))
    local logisticsConfig = require '@cidade_tycoon_logistics/config/shared'
    
    for _, warehouse in pairs(logisticsConfig.warehouses) do
        if warehouse.productionCoords then
            if #(pCoords - warehouse.productionCoords) < Config.ProximityThreshold then
                return true
            end
        end
    end
    return false
end

-- Market Shop (Parts)
lib.callback.register('cidade_tycoon_autoparts:server:purchasePart', function(source, itemName, amount)
    local src = source
    
    -- 1. Anti-Spam Lock
    if activeTransactions[src] then return { ok = false, message = 'Aguarde a transação anterior terminar.' } end
    activeTransactions[src] = true

    local result = pcall(function()
        -- 2. Input Validation
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 or amount > Config.MaxPurchasePerTurn then
            return { ok = false, message = 'Quantidade inválida.' }
        end

        -- 3. Proximity Check
        if not isNearAnyWarehouse(src) then
            return { ok = false, message = 'Você está muito longe da prateleira.' }
        end

        local partData = exports.cidade_tycoon_core:GetPartData(itemName)
        if not partData then return { ok = false, message = 'Peça inválida.' } end

        local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
        local totalPrice = math.floor(partData.price * amount)

        -- 4. Balance Check
        if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < totalPrice then
            return { ok = false, message = ('Saldo insuficiente ($%d).'):format(totalPrice) }
        end

        -- 5. Transaction Execution
        if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', totalPrice, 'tycoon-autoparts-purchase') then
            if exports.ox_inventory:AddItem(src, itemName, amount) then
                exports.cidade_tycoon_core:LogTransaction(src, totalPrice, 'expense', 'purchase', 'Auto Peças: ' .. partData.label)
                DebugLog("Jogador %s comprou %d x %s", player.PlayerData.citizenid, amount, itemName)
                return { ok = true, message = ('Você adquiriu %d x %s!'):format(amount, partData.label) }
            else
                -- Refund on inventory failure
                exports.cidade_tycoon_core:AddMoney(player, 'bank', totalPrice, 'tycoon-autoparts-refund')
                return { ok = false, message = 'Inventário cheio.' }
            end
        end

        return { ok = false, message = 'Falha no processamento financeiro.' }
    end)

    activeTransactions[src] = nil
    return result
end)

-- Recycling Logic (Scrap -> Warehouse Materials)
lib.callback.register('cidade_tycoon_autoparts:server:recycleScrap', function(source, scrapItem)
    local src = source
    
    if activeTransactions[src] then return { ok = false, message = 'Aguarde...' } end
    activeTransactions[src] = true

    local result = pcall(function()
        -- 1. Proximity Check
        if not isNearAnyWarehouse(src) then
            return { ok = false, message = 'Aproxime-se da caçamba de reciclagem.' }
        end

        local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
        local company = exports.cidade_tycoon_logistics:GetCompanyData(src)
        if not company then return { ok = false, message = 'Apenas donos de empresa podem reciclar.' } end

        -- 2. Config Lookup
        local recycleOpt = nil
        for _, opt in ipairs(Config.Recycling.options) do
            if opt.item == scrapItem then
                recycleOpt = opt
                break
            end
        end
        if not recycleOpt then return { ok = false, message = 'Item não reciclável.' } end

        -- 3. Inventory Check
        local item = exports.ox_inventory:GetItem(src, scrapItem, nil, false)
        if not item or item.count < 1 then
            return { ok = false, message = 'Você não possui sucata.' } end

        -- 4. Execution
        if exports.ox_inventory:RemoveItem(src, scrapItem, 1) then
            local success = MySQL.update.await([[
                INSERT INTO tycoon_warehouse_inventory (company_id, item_key, amount)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount)
            ]], { company.id, recycleOpt.reward, recycleOpt.amount })

            if success then
                DebugLog("Empresa %d reciclou %s", company.id, scrapItem)
                return { ok = true, message = ('Reciclagem concluída! +%d %s.'):format(recycleOpt.amount, recycleOpt.reward) }
            end
        end

        return { ok = false, message = 'Falha na reciclagem.' }
    end)

    activeTransactions[src] = nil
    return result
end)
