local leaderboardCache = {}
local lastLeaderboardUpdate = 0

local function DebugLog(text, ...)
    print(string.format("^5[Tycoon:Server:CityHall]^7 %s", string.format(text, ...)))
end

-- Reputation calculation helpers
local function computeReputationScores(source)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return end

    -- Fiscal: based on tax streak
    local fiscalRep = (profile.taxStreak or 0) * 25
    local hybridScore = (profile.level or 1) * 10 + (profile.reputation or 0) + (profile.reputationProduction or 0) + fiscalRep

    exports.cidade_tycoon_core:UpdateProfileField(source, 'reputation_fiscal', fiscalRep)
    exports.cidade_tycoon_core:UpdateProfileField(source, 'hybrid_score', hybridScore)

    return hybridScore, fiscalRep
end

-- City Hall Dashboard
lib.callback.register('cidade_tycoon_cityhall:server:getDashboard', function(source)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return nil end

    local hybridScore = computeReputationScores(source) or profile.hybridScore
    local coreConfig = exports.cidade_tycoon_core:GetCoreConfig()
    local licenseDefs = coreConfig.licenseDefinitions

    -- Dynamic Tax Calculation: Base + (Vehicle Count * Multiplier)
    local vehicleCount = MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ?', { profile.citizenid }) or 0
    local taxAmount = Config.Tax.BaseAmount + (vehicleCount * Config.Tax.PerVehicleAmount)

    -- Leaderboard Cache (30 min)
    if GetGameTimer() - lastLeaderboardUpdate > 1800000 or #leaderboardCache == 0 then
        local topTycoons = MySQL.query.await([[
            SELECT company_name, hybrid_score 
            FROM tycoon_players 
            WHERE hybrid_score > 0
            ORDER BY hybrid_score DESC 
            LIMIT 10
        ]])
        leaderboardCache = topTycoons or {}
        lastLeaderboardUpdate = GetGameTimer()
    end

    local dashboard = {
        reputation = hybridScore,
        taxStreak = profile.taxStreak or 0,
        taxAmount = taxAmount,
        taxDueAt = profile.taxDueAt,
        isSuspended = profile.isSuspended,
        licenses = {},
        leaderboard = leaderboardCache,
    }

    for _, def in ipairs(licenseDefs) do
        local owned = profile.licenses and profile.licenses[def.key] == true
        table.insert(dashboard.licenses, {
            key = def.key,
            label = def.label,
            owned = owned,
            cost = def.cost,
            requiredReputation = def.requiredReputation,
            canBuy = not owned and not profile.isSuspended and hybridScore >= def.requiredReputation
        })
    end

    return dashboard
end)

local function getRichestPlayersLeaderboard(requestedLimit)
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
end

local function getStatueLeaderboardTop10()
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
end

exports('GetRichestPlayersLeaderboard', getRichestPlayersLeaderboard)
exports('GetStatueLeaderboardTop10', getStatueLeaderboardTop10)

-- Deferred Tax Enforcement on Login
AddEventHandler('qbx_core:server:onPlayerLoaded', function(source)
    local src = source
    SetTimeout(Config.Tax.CheckDelayOnLogin, function()
        local profile = exports.cidade_tycoon_core:GetPlayerProfile(src)
        if not profile or not profile.taxDueAt then return end

        local now = os.time()
        local dueTime = math.floor(profile.taxDueAt / 1000) -- Convert from JS ms if needed, or check format
        
        if now > dueTime then
            local diffSeconds = now - dueTime
            local diffDays = math.floor(diffSeconds / 86400)
            
            -- Apply Offline Freeze Protection (Guardian Rule)
            -- If offline > 48h, we only penalize up to 48h + delay.
            -- Simplified: we only process if they are actually active.
            
            if diffDays >= Config.Tax.OverdueGraceDays then
                if not profile.isSuspended then
                    exports.cidade_tycoon_core:UpdateProfileField(src, 'is_suspended', 1)
                    exports.cidade_tycoon_core:NotifyPlayer(src, 'Suas licenças foram SUSPENSAS por débitos fiscais!', 'error')
                end
            elseif diffDays > 0 then
                local fine = diffDays * Config.Tax.DailyFine
                exports.cidade_tycoon_core:NotifyPlayer(src, ('Você possui impostos atrasados! Multa atual: $%d'):format(fine), 'error')
            end
        end
    end)
end)

-- Tax Payment
lib.callback.register('cidade_tycoon_cityhall:server:payTaxes', function(source)
    local src = source
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(src)
    if not profile then return { ok = false, message = 'Perfil não encontrado.' } end

    local vehicleCount = MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ?', { profile.citizenid }) or 0
    local taxAmount = Config.Tax.BaseAmount + (vehicleCount * Config.Tax.PerVehicleAmount)
    
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < taxAmount then
        return { ok = false, message = ('Saldo insuficiente: $%d'):format(taxAmount) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', taxAmount, 'tycoon-city-tax') then
        local nextDue = os.time() + (7 * 24 * 60 * 60)
        
        MySQL.update.await('UPDATE tycoon_players SET tax_streak = tax_streak + 1, tax_due_at = FROM_UNIXTIME(?), is_suspended = 0 WHERE citizenid = ?', {
            nextDue, profile.citizenid
        })

        exports.cidade_tycoon_core:LogTransaction(src, taxAmount, 'expense', 'tax', 'Pagamento de Imposto Territorial')
        exports.cidade_tycoon_core:AddReputation(src, 50)
        
        -- Clear local cache to refresh suspension state
        exports.cidade_tycoon_core:ClearProfileCache(profile.citizenid)

        return { ok = true, message = 'Impostos pagos e licenças regularizadas!', nextDue = os.date('%Y-%m-%d', nextDue) }
    end
    return { ok = false, message = 'Falha no pagamento.' }
end)

-- License Purchase logic (Updated to use Core Config)
lib.callback.register('cidade_tycoon_cityhall:server:purchaseLicense', function(source, licenseKey)
    local src = source
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(src)
    local coreConfig = exports.cidade_tycoon_core:GetCoreConfig()
    
    local targetDef = nil
    for _, def in ipairs(coreConfig.licenseDefinitions) do
        if def.key == licenseKey then targetDef = def break end
    end

    if not targetDef or profile.licenses[licenseKey] then return { ok = false, message = 'Operação inválida.' } end
    
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < targetDef.cost then
        return { ok = false, message = 'Saldo insuficiente.' }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', targetDef.cost, 'tycoon-license-purchase') then
        profile.licenses[licenseKey] = true
        MySQL.update.await('UPDATE tycoon_players SET licenses = ? WHERE citizenid = ?', { json.encode(profile.licenses), profile.citizenid })
        exports.cidade_tycoon_core:ClearProfileCache(profile.citizenid)
        
        return { ok = true, message = ('Habilitação %s adquirida!'):format(targetDef.label) }
    end
    return { ok = false, message = 'Erro no servidor.' }
end)
