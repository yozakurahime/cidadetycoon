local function DebugLog(text, ...)
    print(string.format("^5[Tycoon:Compat]^7 %s", string.format(text, ...)))
end

-- REDIRECT TABLET DASHBOARD (Temporary Bridge)
lib.callback.register('transport_tycoon_infinito:server:getTabletDashboard', function(source)
    DebugLog("Redirecionando getTabletDashboard legado para o modulo tablet.")
    return exports.cidade_tycoon_tablet:GetDashboardForSource(source)
end)

-- REDIRECT FREELANCE CONTEXT
lib.callback.register('transport_tycoon_infinito:server:getCompanyAndFreelanceContext', function(source)
    DebugLog("Redirecionando getCompanyAndFreelanceContext para o modulo freelance.")
    return exports.cidade_tycoon_freelance:GetCompanyAndFreelanceContextForSource(source)
end)

lib.callback.register('transport_tycoon_infinito:server:getUpgradeDashboard', function(source)
    DebugLog("Redirecionando getUpgradeDashboard legado para o modulo maintenance.")
    return exports.cidade_tycoon_maintenance:GetUpgradeDashboardForSource(source)
end)

-- REDIRECT MISSIONS
RegisterNetEvent('transport_tycoon_infinito:server:completeFreelanceMission', function(missionId, vehNetId)
    local src = source
    TriggerEvent('cidade_tycoon_freelance:server:completeFreelanceMission', src, missionId, vehNetId)
end)

-- REDIRECT LEADERBOARDS (City Hall Leaderboard & Richest Leaderboard)
lib.callback.register('transport_tycoon_infinito:server:getRichestPlayersLeaderboard', function(source, requestedLimit)
    local desiredLimit = math.max(5, math.min(50, tonumber(requestedLimit) or 10))
    local rows = MySQL.query.await([[
        SELECT citizenid, charinfo,
               CAST(COALESCE(JSON_UNQUOTE(JSON_EXTRACT(money, '$.cash')), '0') AS UNSIGNED) AS cash,
               CAST(COALESCE(JSON_UNQUOTE(JSON_EXTRACT(money, '$.bank')), '0') AS UNSIGNED) AS bank
        FROM players
        ORDER BY (
            CAST(COALESCE(JSON_UNQUOTE(JSON_EXTRACT(money, '$.cash')), '0') AS UNSIGNED) +
            CAST(COALESCE(JSON_UNQUOTE(JSON_EXTRACT(money, '$.bank')), '0') AS UNSIGNED)
        ) DESC
        LIMIT ?
    ]], { desiredLimit })

    local leaderboard = {}
    for index = 1, #rows do
        local row = rows[index]
        local firstName = 'Unknown'
        local lastName = 'Player'

        if row.charinfo and row.charinfo ~= '' then
            local ok, decoded = pcall(json.decode, row.charinfo)
            if ok and type(decoded) == 'table' then
                firstName = decoded.firstname or firstName
                lastName = decoded.lastname or lastName
            end
        end

        local cash = tonumber(row.cash) or 0
        local bank = tonumber(row.bank) or 0

        table.insert(leaderboard, {
            rank = index,
            citizenId = row.citizenid,
            name = firstName .. " " .. lastName,
            company_name = firstName .. " " .. lastName,
            score = cash + bank,
            hybrid_score = cash + bank,
            total = cash + bank
        })
    end

    return leaderboard
end)

lib.callback.register('transport_tycoon_infinito:server:getStatueLeaderboardTop10', function(source)
    local rows = MySQL.query.await([[
        SELECT tp.citizenid, tp.company_name, tp.hybrid_score, p.charinfo
        FROM tycoon_players tp
        INNER JOIN players p ON p.citizenid = tp.citizenid
        WHERE tp.hybrid_score > 0
        ORDER BY tp.hybrid_score DESC
        LIMIT 10
    ]])

    local leaderboard = {}
    for index = 1, #rows do
        local row = rows[index]
        local firstName = 'Unknown'
        local lastName = 'Player'

        if row.charinfo and row.charinfo ~= '' then
            local ok, decoded = pcall(json.decode, row.charinfo)
            if ok and type(decoded) == 'table' then
                firstName = decoded.firstname or firstName
                lastName = decoded.lastname or lastName
            end
        end

        table.insert(leaderboard, {
            rank = index,
            citizenId = row.citizenid,
            name = row.company_name or (firstName .. " " .. lastName),
            company_name = row.company_name or (firstName .. " " .. lastName),
            score = row.hybrid_score,
            hybrid_score = row.hybrid_score,
            totalReceived = row.hybrid_score
        })
    end

    return leaderboard
end)

