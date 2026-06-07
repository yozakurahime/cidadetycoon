local config = require 'shared.config'
local logBuffer = {}
local isFlushing = false

-- ==========================================
-- HIGH PERFORMANCE LOGGING (Buffered)
-- ==========================================

local function flushLogs()
    if #logBuffer == 0 or isFlushing then return end
    isFlushing = true

    local currentLogs = logBuffer
    logBuffer = {}

    local sqlValues = {}
    local params = {}

    for _, log in ipairs(currentLogs) do
        table.insert(sqlValues, "(?, ?, ?, ?, ?, ?)")
        table.insert(params, log.citizenid)
        table.insert(params, log.type)
        table.insert(params, log.category)
        table.insert(params, log.amount)
        table.insert(params, log.message)
        table.insert(params, log.timestamp)
    end

    local query = ("INSERT INTO tycoon_logs (citizenid, type, category, amount, message, created_at) VALUES %s"):format(table.concat(sqlValues, ","))
    
    MySQL.insert(query, params, function(res)
        isFlushing = false
        if not res then
            print("^1[Tycoon:Core:Logs]^7 Falha ao persistir buffer de logs no banco de dados!")
        end
    end)
end

-- Flush loop
CreateThread(function()
    while true do
        Wait(config.LogFlushInterval)
        flushLogs()
    end
end)

-- Critical log table initialization
CreateThread(function()
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            type ENUM('income', 'expense', 'info', 'error') NOT NULL,
            category VARCHAR(50) NOT NULL,
            amount BIGINT DEFAULT 0,
            message TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX (citizenid),
            INDEX (category)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- Exported function
local function logTransaction(source, amount, type, category, message)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local cid = exports.cidade_tycoon_core:GetCitizenId(player)
    if not cid then return end

    local logEntry = {
        citizenid = cid,
        type = type or 'info',
        category = category or 'general',
        amount = math.floor(tonumber(amount) or 0),
        message = message or '',
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    }

    table.insert(logBuffer, logEntry)

    -- Force flush if critical or buffer full
    if #logBuffer >= config.LogBufferCap or type == 'error' or (type == 'expense' and amount > 50000) then
        flushLogs()
    end
end

exports('LogTransaction', logTransaction)

-- Emergency flush on stop
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    flushLogs()
end)
