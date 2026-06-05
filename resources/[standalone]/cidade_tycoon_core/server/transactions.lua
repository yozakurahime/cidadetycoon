local function logTransaction(source, amount, type, category, description)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return false end

    MySQL.insert.await([[
        INSERT INTO tycoon_transactions (citizenid, amount, type, category, description)
        VALUES (?, ?, ?, ?, ?)
    ]], { citizenId, amount, type, category, description or '' })

    return true
end

local function getPlayerTransactions(source, limit)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return {} end

    return MySQL.query.await([[
        SELECT * FROM tycoon_transactions 
        WHERE citizenid = ? 
        ORDER BY created_at DESC 
        LIMIT ?
    ]], { citizenId, limit or 20 })
end

exports('LogTransaction', logTransaction)
exports('GetPlayerTransactions', getPlayerTransactions)
