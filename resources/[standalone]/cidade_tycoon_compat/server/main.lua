local function DebugLog(text, ...)
    print(string.format("^5[Tycoon:Compat]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- SAFE PROXY HELPER (Guardian Rule)
-- ==========================================
local function safeExportCall(resource, exportName, ...)
    if GetResourceState(resource) ~= 'started' then
        DebugLog("^1ERRO:^7 Recurso '%s' não está iniciado. Export '%s' ignorado.", resource, exportName)
        return nil
    end

    local ok, result = pcall(function(...)
        return exports[resource][exportName](...)
    end, ...)

    if not ok then
        DebugLog("^1ERRO CRÍTICO:^7 Falha ao chamar export '%s:%s' -> %s", resource, exportName, tostring(result))
        return nil
    end

    return result
end

-- ==========================================
-- LEGACY REDIRECTS (transport_tycoon_infinito:*)
-- ==========================================

-- TABLET DASHBOARD
lib.callback.register('transport_tycoon_infinito:server:getTabletDashboard', function(source)
    return safeExportCall('cidade_tycoon_tablet', 'GetDashboardForSource', source)
end)

-- FREELANCE CONTEXT
lib.callback.register('transport_tycoon_infinito:server:getCompanyAndFreelanceContext', function(source)
    return safeExportCall('cidade_tycoon_freelance', 'GetCompanyAndFreelanceContextForSource', source)
end)

-- UPGRADE DASHBOARD
lib.callback.register('transport_tycoon_infinito:server:getUpgradeDashboard', function(source)
    return safeExportCall('cidade_tycoon_maintenance', 'GetUpgradeDashboardForSource', source)
end)

-- LEADERBOARDS (Redirecting to CityHall - centralized logic)
lib.callback.register('transport_tycoon_infinito:server:getRichestPlayersLeaderboard', function(source, limit)
    -- We assume CityHall will have a 'GetWealthLeaderboard' export soon
    -- For now, we use a internal fallback if export is missing
    local data = safeExportCall('cidade_tycoon_cityhall', 'GetWealthLeaderboard', limit)
    if data then return data end
    
    return {} -- Return empty to avoid UI crash if CityHall hasn't implemented it yet
end)

lib.callback.register('transport_tycoon_infinito:server:getStatueLeaderboardTop10', function(source)
    local dashboard = safeExportCall('cidade_tycoon_cityhall', 'getDashboard', source)
    if dashboard and dashboard.leaderboard then
        -- Convert to expected legacy format
        local legacyList = {}
        for i, v in ipairs(dashboard.leaderboard) do
            table.insert(legacyList, {
                rank = i,
                name = v.company_name or v.name,
                score = v.hybrid_score or v.score,
                totalReceived = v.hybrid_score or v.score
            })
        end
        return legacyList
    end
    return {}
end)

-- MISSION EVENTS
RegisterNetEvent('transport_tycoon_infinito:server:completeFreelanceMission', function()
    local src = source
    safeExportCall('cidade_tycoon_freelance', 'CompleteFreelanceMissionForSource', src)
end)

DebugLog("Camada de compatibilidade 2.0 (Resiliente) carregada.")
