local logisticsConfig = require '@cidade_tycoon_logistics/config/shared'

local function DebugLog(text, ...)
    print(string.format("^6[Tycoon:Server:Production]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- PRODUCTION PROCESSOR (Optimized)
-- ==========================================

local function processProductionLines()
    local now = os.time()
    -- Only scan active lines
    local finishedLines = MySQL.query.await('SELECT * FROM tycoon_production_lines WHERE status = "active" AND end_time <= FROM_UNIXTIME(?)', { now })

    if not finishedLines or #finishedLines == 0 then return end

    for _, line in ipairs(finishedLines) do
        local recipe = logisticsConfig.Production.Recipes[line.recipe_key]
        if recipe then
            -- Atomic Transaction for completion (Rule #4)
            MySQL.transaction.await({
                {
                    query = [[
                        INSERT INTO tycoon_warehouse_inventory (company_id, item_key, amount)
                        VALUES (?, ?, ?)
                        ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount)
                    ]],
                    values = { line.company_id, recipe.outputKey or line.recipe_key, recipe.outputAmount or 1 }
                },
                {
                    query = 'UPDATE tycoon_production_lines SET status = "completed" WHERE id = ?',
                    values = { line.id }
                }
            })

            -- Sync notification and XP to owner
            local companyRow = MySQL.single.await('SELECT citizenid FROM tycoon_companies WHERE id = ?', { line.company_id })
            if companyRow then
                local player = exports.qbx_core:GetPlayerByCitizenId(companyRow.citizenid)
                if player then
                    exports.cidade_tycoon_core:AddExperience(player.PlayerData.source, recipe.xp or 50)
                    TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
                        title = 'Produção Tycoon',
                        description = ('Lote de %s finalizado!'):format(recipe.label),
                        type = 'success'
                    })
                end
            end
            DebugLog("Empresa %d concluiu %s", line.company_id, line.recipe_key)
        end
    end
end

CreateThread(function()
    while true do
        processProductionLines()
        Wait(30000)
    end
end)

-- ==========================================
-- CALLBACKS & SECURITY
-- ==========================================

lib.callback.register('cidade_tycoon_production:server:startProduction', function(source, recipeKey)
    local company = exports.cidade_tycoon_logistics:GetCompanyData(source)
    if not company then return { ok = false, message = 'Empresa não encontrada.' } end

    -- 1. Concurrency Cap (Rule #4)
    local activeCount = MySQL.scalar.await('SELECT COUNT(*) FROM tycoon_production_lines WHERE company_id = ? AND status = "active"', { company.id })
    if activeCount >= 3 then
        return { ok = false, message = 'Limite de produção atingido (Máx: 3 linhas simultâneas).' }
    end

    local recipe = logisticsConfig.Production.Recipes[recipeKey]
    if not recipe then return { ok = false, message = 'Receita inválida.' } end

    -- 2. Atomic Start Transaction (Rule #4)
    local queries = {}
    for itemKey, requiredQty in pairs(recipe.inputs) do
        -- Verify inventory first (Read-only check)
        local inv = MySQL.single.await('SELECT amount FROM tycoon_warehouse_inventory WHERE company_id = ? AND item_key = ?', { company.id, itemKey })
        if not inv or inv.amount < requiredQty then
            return { ok = false, message = ('Insumos insuficientes: %s'):format(itemKey) }
        end
        
        table.insert(queries, {
            query = 'UPDATE tycoon_warehouse_inventory SET amount = amount - ? WHERE company_id = ? AND item_key = ?',
            values = { requiredQty, company.id, itemKey }
        })
    end

    local endTime = os.time() + recipe.time
    table.insert(queries, {
        query = 'INSERT INTO tycoon_production_lines (company_id, recipe_key, end_time) VALUES (?, ?, FROM_UNIXTIME(?))',
        values = { company.id, recipeKey, endTime }
    })

    if MySQL.transaction.await(queries) then
        -- Update Entity State Bags for UI tracking (Rule #2)
        -- This logic would iterate through vehicles/props linked to this company
        return { ok = true, message = 'Produção iniciada com sucesso!' }
    end

    return { ok = false, message = 'Erro interno ao iniciar produção.' }
end)

lib.callback.register('cidade_tycoon_production:server:getWarehouseInventory', function(source)
    local company = exports.cidade_tycoon_logistics:GetCompanyData(source)
    if not company then return {} end
    return MySQL.query.await('SELECT item_key, amount FROM tycoon_warehouse_inventory WHERE company_id = ?', { company.id })
end)
