local function DebugLog(text, ...)
    print(string.format("^5[Tycoon:Server:CityHall]^7 %s", string.format(text, ...)))
end

local config = exports.cidade_tycoon_core:GetCoreConfig() -- Assuming we add this export

local lastReputationCompute = {}

-- Reputation calculation helpers
local function computeReputationScores(source)
    local now = GetGameTimer()
    if lastReputationCompute[source] and now - lastReputationCompute[source] < 60000 then
        return -- Throttle to once per minute
    end
    lastReputationCompute[source] = now

    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return end

    -- Fiscal: based on tax streak
    local fiscalRep = profile.taxStreak * 25
    local currentFiscal = profile.reputationFiscal or 0
    
    if fiscalRep ~= currentFiscal then
        exports.cidade_tycoon_core:UpdateProfileField(source, 'reputation_fiscal', fiscalRep)
    end

    local hybridScore = profile.level * 10 + (profile.reputation or 0) + (profile.reputationProduction or 0) + fiscalRep

    exports.cidade_tycoon_core:UpdateProfileField(source, 'hybrid_score', hybridScore)

    return hybridScore
end

-- City Hall Dashboard
lib.callback.register('cidade_tycoon_cityhall:server:getDashboard', function(source)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return nil end

    local hybridScore = computeReputationScores(source) or profile.hybridScore
    local coreConfig = exports.cidade_tycoon_core:GetCoreConfig()
    local licenseDefs = coreConfig.licenseDefinitions

    local dashboard = {
        reputation = hybridScore,
        taxStreak = profile.taxStreak,
        taxDueAt = profile.taxDueAt,
        isSuspended = profile.isSuspended,
        licenses = {},
        leaderboard = {},
    }

    -- Populate License status
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

    -- Global Leaderboard (Top 10 by Hybrid Score)
    local topTycoons = MySQL.query.await([[
        SELECT company_name, hybrid_score 
        FROM tycoon_players 
        WHERE hybrid_score > 0
        ORDER BY hybrid_score DESC 
        LIMIT 10
    ]])

    for _, row in ipairs(topTycoons or {}) do
        table.insert(dashboard.leaderboard, {
            name = row.company_name,
            score = row.hybrid_score
        })
    end

    return dashboard
end)

-- Tax Payment
lib.callback.register('cidade_tycoon_cityhall:server:payTaxes', function(source)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return { ok = false, message = 'Perfil nao encontrado.' } end

    -- Tax calculation: base $1500 + 1% of total earnings (simulated with 500 per level)
    local taxAmount = 1500 + (profile.level * 500)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)

    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < taxAmount then
        return { ok = false, message = ('Saldo insuficiente para impostos: $%d'):format(taxAmount) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', taxAmount, 'tycoon-city-tax') then
        local nextDue = os.time() + (7 * 24 * 60 * 60) -- 7 days
        
        MySQL.update.await('UPDATE tycoon_players SET tax_streak = tax_streak + 1, tax_due_at = FROM_UNIXTIME(?) WHERE citizenid = ?', {
            nextDue, profile.citizenid
        })

        exports.cidade_tycoon_core:LogTransaction(source, taxAmount, 'expense', 'tax', 'Pagamento de Imposto Territorial')
        exports.cidade_tycoon_core:AddReputation(source, 50) -- Bonus for paying on time

        return { ok = true, message = ('Impostos pagos! Proximo vencimento em 7 dias.'), nextDue = os.date('%Y-%m-%d', nextDue) }
    end

    return { ok = false, message = 'Falha ao processar pagamento.' }
end)

-- Purchase License
lib.callback.register('cidade_tycoon_cityhall:server:purchaseLicense', function(source, licenseKey)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return { ok = false, message = 'Perfil nao encontrado.' } end

    if profile.licenses[licenseKey] then return { ok = false, message = 'Voce ja possui esta licença.' } end

    local licenseDefs = TycoonCore.Config.licenseDefinitions
    local targetDef = nil
    for _, def in ipairs(licenseDefs) do
        if def.key == licenseKey then
            targetDef = def
            break
        end
    end

    if not targetDef then return { ok = false, message = 'Licença invalida.' } end

    if profile.hybridScore < targetDef.requiredReputation then
        return { ok = false, message = 'Reputacao insuficiente para esta licença.' }
    end

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < targetDef.cost then
        return { ok = false, message = ('Saldo insuficiente. Custo: $%d'):format(targetDef.cost) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', targetDef.cost, 'tycoon-license-purchase') then
        profile.licenses[licenseKey] = true
        exports.cidade_tycoon_core:UpdateLicenses(source, profile.licenses)
        exports.cidade_tycoon_core:LogTransaction(source, targetDef.cost, 'expense', 'license', ('Compra de habilitação: %s'):format(targetDef.label))

        return { ok = true, message = ('Habilitação %s adquirida com sucesso!'):format(targetDef.label) }
    end

    return { ok = false, message = 'Falha no pagamento.' }
end)
