local config = require 'shared.config'
local sharedVehicles = require 'shared.vehicles'

-- Configuration for Taxes
local TAX_INTERVAL = 7 * 24 * 3600 -- 7 dias em segundos
local HUB_TAX_RATE = 0.02 -- 2% do valor de compra
local IPVA_POPULAR = 500
local IPVA_LUXO = 15000

-- ==========================================
-- TAX CALCULATION
-- ==========================================

local function calculatePlayerTaxes(source)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return nil end

    local citizenId = profile.citizenid
    local totalHubTax = 0
    local totalIPVA = 0
    local details = {}

    -- 1. Hub Tax
    if profile.hubId and profile.hubId > 0 then
        local hub = exports.cidade_tycoon_hubs:GetAllHubs()[profile.hubId]
        if hub then
            local price = hub.purchasePrice or 250000
            local tax = math.floor(price * HUB_TAX_RATE)
            totalHubTax = tax
            table.insert(details, { label = 'Imposto de Sede (' .. hub.name .. ')', amount = tax })
        end
    end

    -- 2. IPVA (Fleet Tax)
    local vehicles = MySQL.query.await('SELECT vehicle FROM player_vehicles WHERE citizenid = ?', { citizenId })
    if vehicles then
        for _, v in ipairs(vehicles) do
            local vehData = exports.cidade_tycoon_core:GetVehicleData(v.vehicle)
            if vehData and vehData.tier >= 1 then
                local isLuxo = (vehData.category == 'super' or vehData.category == 'hyper')
                local amount = isLuxo and IPVA_LUXO or IPVA_POPULAR
                totalIPVA = totalIPVA + amount
                table.insert(details, { label = 'IPVA: ' .. (vehData.label or v.vehicle), amount = amount })
            end
        end
    end

    return {
        total = totalHubTax + totalIPVA,
        details = details,
        hubTax = totalHubTax,
        ipva = totalIPVA
    }
end

-- ==========================================
-- CALLBACKS & EVENTS
-- ==========================================

lib.callback.register('cidade_tycoon_core:server:getPendingTaxes', function(source)
    local taxes = calculatePlayerTaxes(source)
    local row = MySQL.single.await('SELECT last_upkeep_at FROM tycoon_players WHERE citizenid = ?', { exports.cidade_tycoon_core:GetCitizenId(source) })
    
    local lastTax = row and row.last_upkeep_at or 0
    local currentTime = os.time()
    local nextTaxAt = (type(lastTax) == 'number' and lastTax or 0) + TAX_INTERVAL
    
    return {
        taxes = taxes,
        isDue = (currentTime >= nextTaxAt),
        nextTaxAt = nextTaxAt
    }
end)

lib.callback.register('cidade_tycoon_core:server:payTaxes', function(source)
    local taxes = calculatePlayerTaxes(source)
    if not taxes or taxes.total <= 0 then return { ok = false, message = 'Nenhum imposto pendente.' } end

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local balance = exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank')

    if balance < taxes.total then
        return { ok = false, message = ('Saldo insuficiente ($%d necessário).'):format(taxes.total) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', taxes.total, 'tycoon-taxes-payment') then
        local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
        MySQL.update.await('UPDATE tycoon_players SET last_upkeep_at = CURRENT_TIMESTAMP, is_suspended = 0 WHERE citizenid = ?', { citizenId })
        
        exports.cidade_tycoon_core:LogTransaction(source, taxes.total, 'expense', 'tax', 'Pagamento de Impostos e IPVA')
        
        -- Refresh profile
        exports.cidade_tycoon_core:GetPlayerProfile(source)
        
        return { ok = true, message = 'Impostos pagos com sucesso! Licença regularizada.' }
    end

    return { ok = false, message = 'Erro ao processar pagamento.' }
end)

-- Background thread to check for overdue taxes and suspend players
CreateThread(function()
    while true do
        Wait(30 * 60000) -- Check every 30 minutes
        local players = GetPlayers()
        -- In a real scenario, we'd query the DB for all players who are past due and not suspended
        MySQL.query('SELECT citizenid FROM tycoon_players WHERE last_upkeep_at < NOW() - INTERVAL 7 DAY AND is_suspended = 0', {}, function(result)
            if result then
                for _, row in ipairs(result) do
                    MySQL.update('UPDATE tycoon_players SET is_suspended = 1 WHERE citizenid = ?', { row.citizenid })
                    print(("^1[Tycoon:Finance]^7 Jogador %s suspenso por falta de pagamento de impostos."):format(row.citizenid))
                end
            end
        end)
    end
end)
