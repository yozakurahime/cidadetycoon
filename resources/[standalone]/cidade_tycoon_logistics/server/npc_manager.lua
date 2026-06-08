local config = require 'config.shared'
local activeRoutes = {} -- [deliveryId] = routeData (Memory-first simulation)
local lastDBFlush = 0

local function DebugLog(text, ...)
    print(string.format("^4[Tycoon:Logistics:NPC]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- NPC SIMULATION ENGINE (Guardian Rule #1)
-- ==========================================

local function processNPCSimulation()
    local now = GetGameTimer()
    local delta = config.SimulationTick / 1000 -- Seconds elapsed
    local finishedDeliveries = {}

    for id, route in pairs(activeRoutes) do
        -- Update progress based on speedMult trait
        local speed = 0.01 * (route.speedMult or 1.0) -- Base 1% per tick approx
        route.progress = route.progress + speed

        -- Telemetry: Only sync to interested players (Rule #2)
        -- This would be handled via a targeted event to players with Tablet open
        
        if route.progress >= 100.0 then
            table.insert(finishedDeliveries, id)
        end
    end

    -- Process Completions
    for _, id in ipairs(finishedDeliveries) do
        local route = activeRoutes[id]
        activeRoutes[id] = nil
        
        -- Server-authoritative payout
        MySQL.update([[
            UPDATE tycoon_npc_deliveries SET status = 'completed', progress = 100.0 WHERE id = ?
        ]], { id })

        local profit = math.floor(route.reward * 0.7) -- 30% operational cost
        exports.cidade_tycoon_logistics:AddCompanyFunds(route.companyId, profit, 'Entrega NPC concluída: ' .. route.driverName)
        DebugLog("Entrega NPC %d finalizada. Lucro: $%d", id, profit)
    end

    -- Batch DB Flush (Rule #1)
    if now - lastDBFlush > config.DBFlushInterval then
        lastDBFlush = now
        if next(activeRoutes) then
            -- Bulk update progress to DB to survive crashes
            for id, data in pairs(activeRoutes) do
                MySQL.update("UPDATE tycoon_npc_deliveries SET progress = ? WHERE id = ?", { data.progress, id })
            end
        end
    end
end

CreateThread(function()
    -- Load active routes from DB on start
    local rows = MySQL.query.await("SELECT d.*, e.name as driverName FROM tycoon_npc_deliveries d JOIN tycoon_company_employees e ON d.employee_id = e.id WHERE d.status = 'in_progress'")
    for _, row in ipairs(rows) do
        activeRoutes[row.id] = {
            id = row.id,
            companyId = row.company_id,
            progress = row.progress or 0.0,
            reward = row.reward or 0,
            driverName = row.driverName,
            speedMult = 1.0 -- Traits would be loaded here
        }
    end
    DebugLog("Motor de Simulação carregado com %d rotas ativas.", #rows)

    while true do
        Wait(config.SimulationTick)
        processNPCSimulation()
    end
end)

-- ==========================================
-- JOB BOARD CLEANUP (Rule #5)
-- ==========================================
CreateThread(function()
    while true do
        -- Delete only 'posted' (unclaimed) jobs older than 48h
        local result = MySQL.update.await([[
            DELETE FROM tycoon_job_board 
            WHERE status = 'posted' 
            AND created_at < DATE_SUB(NOW(), INTERVAL ? HOUR)
        ]], { config.JobBoard.expireHours })
        
        if result > 0 then
            DebugLog("Limpeza de Mural: %d vagas expiradas removidas.", result)
        end
        Wait(3600000) -- Check every hour
    end
end)
