local logisticsConfig = require '@cidade_tycoon_logistics/config/shared'

local function DebugLog(text, ...)
    print(string.format("^6[Tycoon:Server:Production]^7 %s", string.format(text, ...)))
end

-- Background Processor: Completion Cron
local function processProductionLines()
    local now = os.time()
    local finishedLines = MySQL.query.await('SELECT * FROM tycoon_production_lines WHERE status = "active" AND end_time <= FROM_UNIXTIME(?)', { now })

    if not finishedLines or #finishedLines == 0 then return end

    for _, line in ipairs(finishedLines) do
        local recipe = logisticsConfig.production.recipes[line.recipe_key]
        if recipe then
            -- 1. Award Finished Products
            MySQL.update.await([[
                INSERT INTO tycoon_warehouse_inventory (company_id, item_key, amount)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount)
            ]], { line.company_id, recipe.outputKey or line.recipe_key, recipe.outputAmount or 1 })

            -- 2. Mark as Completed
            MySQL.update.await('UPDATE tycoon_production_lines SET status = "completed" WHERE id = ?', { line.id })

            -- 3. Award XP to the owner
            local companyRow = MySQL.single.await('SELECT citizenid FROM tycoon_companies WHERE id = ?', { line.company_id })
            if companyRow then
                local player = exports.qbx_core:GetPlayerByCitizenId(companyRow.citizenid)
                if player then
                    exports.cidade_tycoon_core:AddExperience(player.PlayerData.source, recipe.xp or 50)
                    TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
                        title = 'Produção Tycoon',
                        description = ('Lote de %s concluído e armazenado!'):format(recipe.label),
                        type = 'success'
                    })
                end
            end
            
            DebugLog("Empresa ID %d concluiu produção de %s", line.company_id, line.recipe_key)
        end
    end
end

CreateThread(function()
    while true do
        processProductionLines()
        Wait(30000) -- Check every 30 seconds
    end
end)

-- Callbacks
lib.callback.register('cidade_tycoon_production:server:getWarehouseInventory', function(source)
    local company = exports.cidade_tycoon_logistics:GetCompanyData(source)
    if not company then return {} end

    local inventory = MySQL.query.await('SELECT item_key, amount FROM tycoon_warehouse_inventory WHERE company_id = ?', { company.id })
    return inventory or {}
end)

lib.callback.register('cidade_tycoon_production:server:buyMaterials', function(source, materialKey, amount)
    local company = exports.cidade_tycoon_logistics:GetCompanyData(source)
    if not company then return { ok = false, message = 'Empresa nao encontrada.' } end

    local material = logisticsConfig.production.materials[materialKey]
    if not material then return { ok = false, message = 'Material invalido.' } end

    local totalPrice = material.price * amount
    
    -- Try to pay from Company Vault
    if exports.cidade_tycoon_logistics:RemoveCompanyFunds(company.id, totalPrice, 'Compra de Insumos') then
        -- Add to Warehouse Inventory
        MySQL.update.await([[
            INSERT INTO tycoon_warehouse_inventory (company_id, item_key, amount)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount)
        ]], { company.id, materialKey, amount })

        return { ok = true, message = ('Compra de %d x %s realizada via caixa da empresa!'):format(amount, material.label) }
    end

    return { ok = false, message = ('Saldo da empresa insuficiente ($%d necessário).'):format(totalPrice) }
end)

lib.callback.register('cidade_tycoon_production:server:startProduction', function(source, recipeKey)
    local company = exports.cidade_tycoon_logistics:GetCompanyData(source)
    if not company then return { ok = false, message = 'Empresa nao encontrada.' } end

    local recipe = logisticsConfig.production.recipes[recipeKey]
    if not recipe then return { ok = false, message = 'Receita invalida.' } end

    -- Verify Inputs
    for itemKey, requiredAmount in pairs(recipe.inputs) do
        local inv = MySQL.single.await('SELECT amount FROM tycoon_warehouse_inventory WHERE company_id = ? AND item_key = ?', { company.id, itemKey })
        if not inv or inv.amount < requiredAmount then
            return { ok = false, message = ('Insumos insuficientes (%s).'):format(itemKey) }
        end
    end

    -- Consume Inputs
    for itemKey, requiredAmount in pairs(recipe.inputs) do
        MySQL.update.await('UPDATE tycoon_warehouse_inventory SET amount = amount - ? WHERE company_id = ? AND item_key = ?', { requiredAmount, company.id, itemKey })
    end

    -- Start Production
    local endTime = os.time() + recipe.time
    MySQL.insert.await([[
        INSERT INTO tycoon_production_lines (company_id, recipe_key, end_time)
        VALUES (?, ?, FROM_UNIXTIME(?))
    ]], { company.id, recipeKey, endTime })

    DebugLog("Empresa %s iniciou produção de %s", company.name, recipeKey)

    return { ok = true, message = 'Produção iniciada! Confira o status no tablet.' }
end)
