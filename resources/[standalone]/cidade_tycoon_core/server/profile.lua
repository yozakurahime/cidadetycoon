local config = require 'shared.config'

local PlayerProfiles = {}

-- ==========================================
-- DATABASE INITIALIZATION
-- ==========================================
local function createTycoonTables()
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_players (
            id INT NOT NULL AUTO_INCREMENT,
            citizenid VARCHAR(50) NOT NULL,
            company_name VARCHAR(80) DEFAULT 'Transportes Tycoon',
            hub_id INT DEFAULT NULL,
            level INT DEFAULT 1,
            experience INT DEFAULT 0,
            reputation INT DEFAULT 0,
            reputation_production INT DEFAULT 0,
            reputation_fiscal INT DEFAULT 0,
            hybrid_score INT DEFAULT 0,
            tax_streak INT DEFAULT 0,
            tax_due_at TIMESTAMP NULL DEFAULT NULL,
            licenses LONGTEXT DEFAULT NULL,
            skills LONGTEXT DEFAULT NULL,
            upgrades LONGTEXT DEFAULT NULL,
            insurance_tier INT DEFAULT 0,
            vault_balance INT NOT NULL DEFAULT 0,
            is_suspended TINYINT(1) NOT NULL DEFAULT 0,
            last_upkeep_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            tutorial_current_step VARCHAR(64) DEFAULT 'welcome',
            tutorial_assigned_garage VARCHAR(64) DEFAULT NULL,
            tutorial_assigned_hub_id INT DEFAULT NULL,
            tutorial_completed_at TIMESTAMP NULL DEFAULT NULL,
            active_plate VARCHAR(15) DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY (citizenid)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Check if columns exist for existing installations
    pcall(function()
        local columns = MySQL.query.await("SHOW COLUMNS FROM tycoon_players")
        local existingCols = {}
        for _, col in ipairs(columns) do existingCols[col.Field] = true end

        if not existingCols['vault_balance'] then MySQL.update.await("ALTER TABLE tycoon_players ADD COLUMN vault_balance INT NOT NULL DEFAULT 0") end
        if not existingCols['is_suspended'] then MySQL.update.await("ALTER TABLE tycoon_players ADD COLUMN is_suspended TINYINT(1) NOT NULL DEFAULT 0") end
        if not existingCols['last_upkeep_at'] then MySQL.update.await("ALTER TABLE tycoon_players ADD COLUMN last_upkeep_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP") end
        if not existingCols['tutorial_current_step'] then MySQL.update.await("ALTER TABLE tycoon_players ADD COLUMN tutorial_current_step VARCHAR(64) DEFAULT 'welcome'") end
        if not existingCols['tutorial_assigned_garage'] then MySQL.update.await("ALTER TABLE tycoon_players ADD COLUMN tutorial_assigned_garage VARCHAR(64) DEFAULT NULL") end
        if not existingCols['tutorial_assigned_hub_id'] then MySQL.update.await("ALTER TABLE tycoon_players ADD COLUMN tutorial_assigned_hub_id INT DEFAULT NULL") end
        if not existingCols['tutorial_completed_at'] then MySQL.update.await("ALTER TABLE tycoon_players ADD COLUMN tutorial_completed_at TIMESTAMP NULL DEFAULT NULL") end
        if not existingCols['active_plate'] then MySQL.update.await("ALTER TABLE tycoon_players ADD COLUMN active_plate VARCHAR(15) DEFAULT NULL") end
    end)

    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_vehicle_status (
            plate VARCHAR(15) NOT NULL,
            mileage FLOAT DEFAULT 0.0,
            engine_health FLOAT DEFAULT 100.0,
            transmission_health FLOAT DEFAULT 100.0,
            brakes_health FLOAT DEFAULT 100.0,
            suspension_health FLOAT DEFAULT 100.0,
            tires_health FLOAT DEFAULT 100.0,
            last_service TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (plate)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_transactions (
            id INT NOT NULL AUTO_INCREMENT,
            citizenid VARCHAR(50) NOT NULL,
            amount INT NOT NULL,
            type VARCHAR(20) NOT NULL, -- 'income' or 'expense'
            category VARCHAR(30) NOT NULL, -- 'freelance', 'purchase', 'repair', 'installment', 'recruitment'
            description VARCHAR(255) DEFAULT '',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            INDEX (citizenid),
            INDEX (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_companies (
            id INT NOT NULL AUTO_INCREMENT,
            citizenid VARCHAR(50) NOT NULL,
            name VARCHAR(100) NOT NULL DEFAULT 'Logística Tycoon',
            level INT DEFAULT 1,
            experience INT DEFAULT 0,
            vault_balance INT DEFAULT 0,
            warehouse_id INT NOT NULL,
            upgrades LONGTEXT DEFAULT NULL,
            is_active TINYINT(1) DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY (citizenid),
            INDEX (warehouse_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_company_employees (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            hub_id INT DEFAULT NULL,
            name VARCHAR(100) NOT NULL,
            skill_level INT DEFAULT 1,
            salary INT DEFAULT 0,
            status VARCHAR(20) DEFAULT 'idle', -- 'idle', 'working', 'resting'
            last_work_at TIMESTAMP NULL DEFAULT NULL,
            PRIMARY KEY (id),
            INDEX (company_id),
            INDEX (hub_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_company_fleet (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            hub_id INT DEFAULT NULL,
            plate VARCHAR(15) NOT NULL,
            model VARCHAR(50) NOT NULL,
            condition_score FLOAT DEFAULT 100.0,
            PRIMARY KEY (id),
            UNIQUE KEY (plate),
            INDEX (company_id),
            INDEX (hub_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_job_board (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            title VARCHAR(100) NOT NULL,
            reward INT NOT NULL,
            cargo_type VARCHAR(30) DEFAULT 'standard',
            origin_coords LONGTEXT NOT NULL,
            dest_coords LONGTEXT NOT NULL,
            status VARCHAR(20) DEFAULT 'posted', -- 'posted', 'accepted', 'completed'
            accepted_by VARCHAR(50) DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            INDEX (company_id),
            INDEX (status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_npc_deliveries (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            employee_id INT NOT NULL,
            vehicle_plate VARCHAR(15) NOT NULL,
            reward INT NOT NULL,
            status VARCHAR(20) DEFAULT 'in_progress',
            ends_at TIMESTAMP NOT NULL,
            PRIMARY KEY (id),
            INDEX (company_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_financings (
            id INT NOT NULL AUTO_INCREMENT,
            citizenid VARCHAR(50) NOT NULL,
            vehicle_model VARCHAR(50) NOT NULL,
            plate VARCHAR(15) NOT NULL,
            total_price INT NOT NULL,
            amount_paid INT DEFAULT 0,
            installments_paid INT DEFAULT 0,
            total_installments INT NOT NULL,
            installment_amount INT NOT NULL,
            last_payment TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_active TINYINT(1) DEFAULT 1,
            PRIMARY KEY (id),
            INDEX (citizenid),
            UNIQUE KEY (plate)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_warehouse_inventory (
            company_id INT NOT NULL,
            item_key VARCHAR(50) NOT NULL,
            amount INT NOT NULL DEFAULT 0,
            PRIMARY KEY (company_id, item_key),
            INDEX (company_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- okokBanking Tables
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS okokBanking_societies (
            society VARCHAR(100) NOT NULL,
            society_name VARCHAR(100) NOT NULL,
            value INT NOT NULL DEFAULT 0,
            iban VARCHAR(50) NOT NULL,
            is_withdrawing TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (society)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS okokBanking_transactions (
            id INT NOT NULL AUTO_INCREMENT,
            receiver_identifier VARCHAR(255) NOT NULL,
            receiver_name VARCHAR(255) NOT NULL,
            sender_identifier VARCHAR(255) NOT NULL,
            sender_name VARCHAR(255) NOT NULL,
            amount INT NOT NULL,
            type VARCHAR(50) NOT NULL,
            date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Add missing columns to players table (Compatibility with core_inventory)
    pcall(function()
        local columns = MySQL.query.await("SHOW COLUMNS FROM players")
        local existingCols = {}
        for _, col in ipairs(columns) do existingCols[col.Field] = true end

        if not existingCols['inventory'] then MySQL.update.await("ALTER TABLE players ADD COLUMN inventory LONGTEXT DEFAULT '[]'") end
        if not existingCols['inventorysettings'] then MySQL.update.await("ALTER TABLE players ADD COLUMN inventorysettings LONGTEXT DEFAULT NULL") end
    end)

    -- Register Tycoon Items in Global Items Table (Compatibility with core_inventory)
    local itemsToRegister = {
        { 'engine_block', 'Bloco do Motor', 7500, 2, 2, 'misc', 'Componente pesado para reparos.' },
        { 'transmission_gear', 'Engrenagem de Transmissão', 4000, 2, 1, 'misc', 'Engrenagens industriais.' },
        { 'brake_pads', 'Pastilhas de Freio', 500, 1, 1, 'misc', 'Item de desgaste médio.' },
        { 'suspension_arm', 'Braço de Suspensão', 2000, 1, 2, 'misc', 'Componente de chassis.' },
        { 'truck_tire', 'Pneu Reforçado', 5000, 2, 2, 'misc', 'Pneu para veículos de carga.' },
        { 'basic_repair_kit', 'Kit de Reparo Básico', 1500, 1, 1, 'misc', 'Consumível para reparos leves.' },
        { 'mechanical_scrap', 'Sucata Mecânica', 2500, 1, 1, 'misc', 'Restos de metal para reciclagem.' },
        { 'electronic_scrap', 'Sucata Eletrônica', 1000, 1, 1, 'misc', 'Circuitos e chips para reciclagem.' },
        { 'rubber_scrap', 'Sucata de Borracha', 1500, 1, 1, 'misc', 'Pneus velhos para reciclagem.' },
        { 'tablet', 'Tablet de Transportes', 500, 1, 1, 'misc', 'Interface operacional tycoon.' }
    }

    for _, item in ipairs(itemsToRegister) do
        MySQL.update.await([[
            INSERT IGNORE INTO items (name, label, weight, x, y, category, description)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], { item[1], item[2], item[3], item[4], item[5], item[6], item[7] })
    end

    -- Add missing columns to player_vehicles
    pcall(function()
        local columns = MySQL.query.await("SHOW COLUMNS FROM player_vehicles")
        local existingCols = {}
        for _, col in ipairs(columns) do existingCols[col.Field] = true end

        if not existingCols['insurance_expiry'] then 
            MySQL.update.await("ALTER TABLE player_vehicles ADD COLUMN insurance_expiry TIMESTAMP NULL DEFAULT NULL") 
        end
    end)
end

-- ==========================================
-- CORE PROFILE LOGIC
-- ==========================================

local function syncPlayerState(source, profile)
    if not profile then return end
    Player(source).state:set('tycoonProfile', profile, true)
end

local function getPlayerProfile(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return nil end

    if PlayerProfiles[citizenId] then
        return PlayerProfiles[citizenId]
    end

    local row = MySQL.single.await('SELECT * FROM tycoon_players WHERE citizenid = ?', { citizenId })

    if not row then
        -- Create default profile
        local skills = json.encode(config.skillDefaults)
        local upgrades = json.encode(config.upgradeDefaults)
        local licenses = json.encode({ driver = true, truck = false, heli = false, pilot = false })

        MySQL.insert.await([[
            INSERT INTO tycoon_players (citizenid, level, experience, reputation, licenses, skills, upgrades)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], { citizenId, 1, 0, 0, licenses, skills, upgrades })

        row = {
            citizenid = citizenId,
            company_name = 'Transportes Tycoon',
            hub_id = nil,
            level = 1,
            experience = 0,
            reputation = 0,
            licenses = licenses,
            skills = skills,
            upgrades = upgrades
        }
    end

    local profile = {
        citizenid = row.citizenid,
        companyName = row.company_name or 'Transportes Tycoon',
        hubId = row.hub_id,
        level = row.level or 1,
        experience = row.experience or 0,
        maxExperience = (row.level or 1) * config.experiencePerLevel,
        reputation = row.reputation or 0,
        reputationProduction = row.reputation_production or 0,
        reputationFiscal = row.reputation_fiscal or 0,
        hybridScore = row.hybrid_score or 0,
        taxStreak = row.tax_streak or 0,
        taxDueAt = row.tax_due_at,
        insuranceTier = row.insurance_tier or 0,
        vaultBalance = row.vault_balance or 0,
        isSuspended = (row.is_suspended == 1),
        lastUpkeepAt = row.last_upkeep_at,
        activePlate = row.active_plate,
        tutorial = {
            currentStep = row.tutorial_current_step or 'welcome',
            assignedGarage = row.tutorial_assigned_garage,
            assignedHubId = row.tutorial_assigned_hub_id,
            completedAt = row.tutorial_completed_at,
            active = (row.tutorial_completed_at == nil)
        },
        licenses = row.licenses and json.decode(row.licenses) or { driver = true },
        skills = row.skills and json.decode(row.skills) or config.skillDefaults,
        upgrades = row.upgrades and json.decode(row.upgrades) or config.upgradeDefaults
    }

    PlayerProfiles[citizenId] = profile

    -- Sync Cruiser for Tutorial if missing
    if profile.tutorial.active and (profile.tutorial.currentStep == 'go_to_garage' or profile.tutorial.currentStep == 'retrieve_bike') then
        local existingVehicle = MySQL.single.await('SELECT id FROM player_vehicles WHERE citizenid = ? AND vehicle = ? LIMIT 1', { profile.citizenid, 'cruiser' })
        if not existingVehicle and GetResourceState('qbx_vehicles') == 'started' then
            pcall(function()
                exports.qbx_vehicles:CreatePlayerVehicle({
                    citizenid = profile.citizenid,
                    model = 'cruiser',
                    garage = 'motelgarage',
                    props = { engineHealth = 1000, bodyHealth = 1000, fuelLevel = 100 }
                })
            end)
        end
    end

    syncPlayerState(source, profile)
    return profile
end

local function getProfileByCitizenId(citizenId)
    if not citizenId then return nil end
    if PlayerProfiles[citizenId] then return PlayerProfiles[citizenId] end

    local row = MySQL.single.await('SELECT * FROM tycoon_players WHERE citizenid = ?', { citizenId })
    if not row then return nil end

    return {
        citizenid = row.citizenid,
        companyName = row.company_name or 'Transportes Tycoon',
        hubId = row.hub_id,
        level = row.level or 1,
        experience = row.experience or 0,
        reputation = row.reputation or 0,
        reputationProduction = row.reputation_production or 0,
        reputationFiscal = row.reputation_fiscal or 0,
        hybridScore = row.hybrid_score or 0,
        licenses = row.licenses and json.decode(row.licenses) or { driver = true },
        skills = row.skills and json.decode(row.skills) or config.skillDefaults,
        upgrades = row.upgrades and json.decode(row.upgrades) or config.upgradeDefaults,
        vaultBalance = row.vault_balance or 0,
        isSuspended = (row.is_suspended == 1)
    }
end

-- ==========================================
-- UPDATE FUNCTIONS
-- ==========================================

local validProfileFields = {
    ['company_name'] = { key = 'companyName', persistent = true },
    ['reputation'] = { key = 'reputation', persistent = true },
    ['reputation_production'] = { key = 'reputationProduction', persistent = true },
    ['reputation_fiscal'] = { key = 'reputationFiscal', persistent = true },
    ['hybrid_score'] = { key = 'hybridScore', persistent = true },
    ['tax_streak'] = { key = 'taxStreak', persistent = true },
    ['vault_balance'] = { key = 'vaultBalance', persistent = true },
    ['is_suspended'] = { key = 'isSuspended', persistent = true },
    ['active_plate'] = { key = 'activePlate', persistent = true },
    ['hub_id'] = { key = 'hubId', persistent = true },
    ['active_mission'] = { key = 'activeMission', persistent = false }
}

local function updateProfileField(source, field, value)
    local profile = getPlayerProfile(source)
    if not profile then return false end

    local fieldDef = validProfileFields[field]
    if not fieldDef then
        print(string.format("^1[Tycoon:Core:Profile]^7 Campo invalido: %s", tostring(field)))
        return false
    end

    profile[fieldDef.key] = value

    if fieldDef.persistent then
        MySQL.update.await(('UPDATE tycoon_players SET %s = ? WHERE citizenid = ?'):format(field), {
            value, profile.citizenid
        })
    end

    syncPlayerState(source, profile)
    return true
end

local function addExperience(source, amount)
    local profile = getPlayerProfile(source)
    if not profile then return false end

    profile.experience = profile.experience + amount
    local nextLevelExp = profile.level * config.experiencePerLevel

    local leveledUp = false
    while profile.experience >= nextLevelExp and profile.level < config.maxLevel do
        leveledUp = true
        profile.experience = profile.experience - nextLevelExp
        profile.level = profile.level + 1
        nextLevelExp = profile.level * config.experiencePerLevel
    end

    MySQL.update.await('UPDATE tycoon_players SET level = ?, experience = ? WHERE citizenid = ?', { profile.level, profile.experience, profile.citizenid })
    syncPlayerState(source, profile)

    TriggerClientEvent('tycoon:client:onExperienceGained', source, {
        amount = amount,
        totalExperience = profile.experience,
        level = profile.level,
        leveledUp = leveledUp
    })

    return true, leveledUp, profile.level
end

local function addReputation(source, repType, amount)
    local profile = getPlayerProfile(source)
    if not profile then return false end

    local field = 'reputation'
    if repType == 'production' then field = 'reputation_production'
    elseif repType == 'fiscal' then field = 'reputation_fiscal' end

    local currentVal = profile[validProfileFields[field].key] or 0
    return updateProfileField(source, field, currentVal + amount)
end

local function updateSkills(source, skillsTable)
    local profile = getPlayerProfile(source)
    if not profile then return false end
    profile.skills = skillsTable
    MySQL.update.await('UPDATE tycoon_players SET skills = ? WHERE citizenid = ?', { json.encode(profile.skills), profile.citizenid })
    syncPlayerState(source, profile)
    return true
end

local function updateUpgrades(source, upgradesTable)
    local profile = getPlayerProfile(source)
    if not profile then return false end
    profile.upgrades = upgradesTable
    MySQL.update.await('UPDATE tycoon_players SET upgrades = ? WHERE citizenid = ?', { json.encode(profile.upgrades), profile.citizenid })
    syncPlayerState(source, profile)
    return true
end

local function updateLicenses(source, licensesTable)
    local profile = getPlayerProfile(source)
    if not profile then return false end
    profile.licenses = licensesTable
    MySQL.update.await('UPDATE tycoon_players SET licenses = ? WHERE citizenid = ?', { json.encode(profile.licenses), profile.citizenid })
    syncPlayerState(source, profile)
    return true
end

local function updateTutorialStep(source, nextStep, options)
    local profile = getPlayerProfile(source)
    if not profile then return false end

    profile.tutorial.currentStep = nextStep
    if options then
        if options.assignedGarage then profile.tutorial.assignedGarage = options.assignedGarage end
        if options.assignedHubId then profile.tutorial.assignedHubId = options.assignedHubId end
        if options.completed then 
            profile.tutorial.completedAt = os.date('%Y-%m-%d %H:%M:%S')
            profile.tutorial.active = false
        end
    end

    MySQL.update.await([[
        UPDATE tycoon_players 
        SET tutorial_current_step = ?, tutorial_assigned_garage = ?, tutorial_assigned_hub_id = ?, tutorial_completed_at = ?
        WHERE citizenid = ?
    ]], { 
        profile.tutorial.currentStep, 
        profile.tutorial.assignedGarage, 
        profile.tutorial.assignedHubId, 
        profile.tutorial.completedAt, 
        profile.citizenid 
    })

    syncPlayerState(source, profile)
    return true
end

local function addCompanyExperience(source, amount)
    local profile = getPlayerProfile(source)
    if not profile then return false end

    local company = MySQL.single.await('SELECT * FROM tycoon_companies WHERE citizenid = ?', { profile.citizenid })
    if not company then return false end

    local newExp = (company.experience or 0) + amount
    local nextLevelExp = (company.level or 1) * 5000
    local newLevel = company.level or 1

    if newExp >= nextLevelExp then
        newExp = newExp - nextLevelExp
        newLevel = newLevel + 1
        TriggerClientEvent('ox_lib:notify', source, { title = 'Empresa Up!', description = ('Sua empresa subiu para o Nível %d!'):format(newLevel), type = 'success' })
    end

    MySQL.update.await('UPDATE tycoon_companies SET experience = ?, level = ? WHERE id = ?', { newExp, newLevel, company.id })
    return true
end

-- ==========================================
-- TAX COMPLIANCE SYSTEM
-- ==========================================
local function processTaxCompliance()
    local now = os.date('%Y-%m-%d %H:%M:%S')
    local overdue = MySQL.query.await('SELECT citizenid FROM tycoon_players WHERE is_suspended = 0 AND tax_due_at < ?', { now })
    if not overdue or #overdue == 0 then return end

    for _, row in ipairs(overdue) do
        MySQL.update.await('UPDATE tycoon_players SET is_suspended = 1, tax_streak = 0 WHERE citizenid = ?', { row.citizenid })
        local player = exports.qbx_core:GetPlayerByCitizenId(row.citizenid)
        if player then
            PlayerProfiles[row.citizenid] = nil
            getPlayerProfile(player.PlayerData.source)
            TriggerClientEvent('ox_lib:notify', player.PlayerData.source, { title = 'Receita Federal LS', description = 'Licença suspensa por inadimplência fiscal!', type = 'error' })
        end
    end
end

CreateThread(function()
    while true do
        processTaxCompliance()
        Wait(60 * 60 * 1000)
    end
end)

-- ==========================================
-- EVENT HANDLERS & EXPORTS
-- ==========================================
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    createTycoonTables()
end)

AddEventHandler('qbx_core:server:onPlayerLoaded', function(source)
    getPlayerProfile(source)
end)

AddEventHandler('qbx_core:server:onPlayerUnload', function(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if citizenId then PlayerProfiles[citizenId] = nil end
end)

exports('GetPlayerProfile', getPlayerProfile)
exports('GetProfileByCitizenId', getProfileByCitizenId)
exports('UpdateProfileField', updateProfileField)
exports('AddExperience', addExperience)
exports('AddReputation', addReputation)
exports('AddCompanyExperience', addCompanyExperience)
exports('UpdateSkills', updateSkills)
exports('UpdateUpgrades', updateUpgrades)
exports('UpdateLicenses', updateLicenses)
exports('UpdateTutorialStep', updateTutorialStep)
exports('UpdateActivePlate', function(s, p) return updateProfileField(s, 'active_plate', p) end)
exports('AddVaultFunds', function(s, a) 
    local p = getPlayerProfile(s)
    if p then return updateProfileField(s, 'vault_balance', p.vaultBalance + a) end
end)

exports('GetUpgradesDefinition', function() return TycoonCore.Upgrades end)
exports('CalculateUpgradeCost', function(k, l) return TycoonCore.CalculateUpgradeCost(k, l) end)
exports('FormatUpgradeEffects', function(s) return TycoonCore.FormatUpgradeEffects(s) end)

-- Legacy Bridge Exports
exports('GetTycoonUpgradeState', function(c) local p = getProfileByCitizenId(c) return p and p.upgrades or config.upgradeDefaults end)
exports('GetTycoonSkillLevels', function(c) local p = getProfileByCitizenId(c) return p and p.skills or config.skillDefaults end)
exports('HasTycoonCompany', function(c) return getProfileByCitizenId(c) ~= nil end)
