local sharedConfig = require 'config.shared'
local CompanyCache = {}

local function DebugLog(text, ...)
    print(string.format("^4[Tycoon:Logistics]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- AUTHORIZATION (Rule #2)
-- ==========================================
local function canWithdraw(source, company, amount)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local cid = exports.cidade_tycoon_core:GetCitizenId(player)
    
    if company.citizenid == cid then return true end -- Owner always can

    -- Check Manager Permissions
    if company.manager_id == cid then
        local limit = company.daily_withdraw_limit or sharedConfig.ManagerDefaults.dailyWithdrawLimit
        -- Simplified for audit: check if amount is within limit
        if amount <= limit then return true end
    end

    return false
end

-- ==========================================
-- COMPANY DATA ENGINE
-- ==========================================

local function getCompanyData(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return nil end

    if CompanyCache[citizenId] then return CompanyCache[citizenId] end

    local row = MySQL.single.await('SELECT * FROM tycoon_companies WHERE citizenid = ? OR manager_id = ?', { citizenId, citizenId })
    if row then
        CompanyCache[citizenId] = row
        return row
    end
    return nil
end

local function getBusinessDashboardForSource(source)
    local company = getCompanyData(source)
    if not company then return { hasCompany = false } end

    local employees = MySQL.query.await('SELECT * FROM tycoon_company_employees WHERE company_id = ?', { company.id })
    local activeDeliveries = MySQL.query.await("SELECT * FROM tycoon_npc_deliveries WHERE company_id = ? AND status = 'active'", { company.id })
    
    return {
        hasCompany = true,
        company = company,
        employees = employees or {},
        activeDeliveries = activeDeliveries or {}
    }
end

-- ==========================================
-- VAULT CORE LOGIC (Rule #4)
-- ==========================================

local function addCompanyFunds(companyId, amount, reason)
    MySQL.update.await('UPDATE tycoon_companies SET vault_balance = vault_balance + ? WHERE id = ?', { amount, companyId })
    -- Invalidate all related caches
    CompanyCache = {} 
    return true
end

local function removeCompanyFunds(companyId, amount, reason, isWithdrawal, source)
    local row = MySQL.single.await('SELECT * FROM tycoon_companies WHERE id = ?', { companyId })
    if not row then return false end

    if row.vault_balance < 0 and isWithdrawal then
        if source then exports.cidade_tycoon_core:NotifyPlayer(source, 'Saques bloqueados: Empresa em débito.', 'error') end
        return false 
    end

    if row.vault_balance < amount and isWithdrawal then return false end

    MySQL.update.await('UPDATE tycoon_companies SET vault_balance = vault_balance - ? WHERE id = ?', { amount, companyId })
    
    if row.vault_balance - amount < 0 then
        MySQL.update('UPDATE tycoon_companies SET in_debt_since = NOW() WHERE id = ? AND in_debt_since IS NULL', { companyId })
    elseif row.vault_balance - amount >= 0 then
        MySQL.update('UPDATE tycoon_companies SET in_debt_since = NULL WHERE id = ?', { companyId })
    end
    
    CompanyCache = {} 
    return true
end

-- ==========================================
-- RECRUITMENT & MANAGEMENT
-- ==========================================

lib.callback.register('cidade_tycoon_logistics:server:hireEmployee', function(source, name, traitKey)
    local company = getCompanyData(source)
    if not company then return { ok = false, message = 'Você não possui uma empresa.' } end

    local cost = 2500
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)

    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < cost then
        return { ok = false, message = 'Saldo insuficiente para contratação.' }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', cost, 'tycoon-hiring') then
        MySQL.insert.await([[
            INSERT INTO tycoon_company_employees (company_id, name, trait)
            VALUES (?, ?, ?)
        ]], { company.id, name, traitKey })
        return { ok = true, message = ('Motorista %s contratado!'):format(name) }
    end
    return { ok = false, message = 'Falha no processamento.' }
end)

-- ==========================================
-- FORECLOSURE CRONJOB
-- ==========================================
CreateThread(function()
    while true do
        local foreclosed = MySQL.update.await([[
            UPDATE tycoon_companies 
            SET is_active = 0, foreclosed_at = NOW() 
            WHERE vault_balance < 0 
            AND in_debt_since < DATE_SUB(NOW(), INTERVAL ? DAY)
            AND is_active = 1
        ]], { sharedConfig.GracePeriodDays })
        if foreclosed > 0 then DebugLog("GOVERNO: %d empresas fechadas.", foreclosed) end
        Wait(86400000)
    end
end)

-- EXPORTS
exports('GetCompanyData', getCompanyData)
exports('AddCompanyFunds', addCompanyFunds)
exports('RemoveCompanyFunds', removeCompanyFunds)
exports('GetBusinessDashboardForSource', getBusinessDashboardForSource)
