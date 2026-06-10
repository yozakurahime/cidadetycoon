local config = require 'config.shared'
local activeRoutes = {}

local function DebugLog(text, ...)
    print(string.format("^4[Tycoon:Logistics:NPC]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- NPC SIMULATION ENGINE (Timestamp-Based)
-- ==========================================

local function calculateDeliveryETA(reward, speedMult)
    -- Simple formula: higher reward takes longer, speedMult reduces time
    -- Base: 10 minutes per $10k reward, minimum 5 minutes
    local baseMinutes = math.max(5, (reward / 10000) * 10)
    local actualMinutes = baseMinutes / (speedMult or 1.0)
    return actualMinutes * 60 -- returns seconds
end

local function processNPCSimulation()
    local finishedDeliveries = {}

    for id, route in pairs(activeRoutes) do
        if os.time() >= route.eta then
            table.insert(finishedDeliveries, id)
        else
            -- Calculate accurate progress % based on time elapsed
            local totalDuration = route.eta - route.start_time
            local elapsed = os.time() - route.start_time
            route.progress = math.min(100.0, (elapsed / totalDuration) * 100.0)
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
        
        -- Notify Tablet (Real-Time Push)
        local owner = MySQL.single.await('SELECT citizenid FROM tycoon_companies WHERE id = ?', { route.companyId })
        if owner then
            local target = exports.cidade_tycoon_core:GetPlayerFromCitizenId(owner.citizenid)
            if target then
                TriggerClientEvent('cidade_tycoon_tablet:client:pushUpdate', target.source, { type = 'logistics', refresh = true })
            end
        end
    end
end

CreateThread(function()
    -- Load active routes from DB on start
    local rows = MySQL.query.await("SELECT d.*, e.name as driverName, UNIX_TIMESTAMP(d.start_time) as start_ts, UNIX_TIMESTAMP(d.eta) as eta_ts FROM tycoon_npc_deliveries d JOIN tycoon_company_employees e ON d.employee_id = e.id WHERE d.status = 'in_progress'")
    for _, row in ipairs(rows) do
        -- If ETA wasn't set (legacy data), calculate it now
        local eta = row.eta_ts
        local startTime = row.start_ts
        
        if not eta then
            local durationSecs = calculateDeliveryETA(row.reward or 5000, 1.0)
            eta = startTime + durationSecs
            MySQL.update("UPDATE tycoon_npc_deliveries SET eta = FROM_UNIXTIME(?) WHERE id = ?", { eta, row.id })
        end

        activeRoutes[row.id] = {
            id = row.id,
            companyId = row.company_id,
            progress = row.progress or 0.0,
            reward = row.reward or 0,
            driverName = row.driverName,
            start_time = startTime,
            eta = eta
        }
    end
    DebugLog("Motor de Simulação carregado com %d rotas ativas (Baseado em Timestamp).", #rows)

    while true do
        Wait(30000) -- Check every 30 seconds instead of every tick
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
