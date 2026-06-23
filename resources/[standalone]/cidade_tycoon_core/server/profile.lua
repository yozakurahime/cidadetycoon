local config = require 'shared.config'
local PlayerProfiles = {}

-- ==========================================
-- DATABASE INITIALIZATION
-- ==========================================
local function createTycoonTables()
    -- Ensure Tycoon Players Table
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
            vault_balance BIGINT NOT NULL DEFAULT 0,
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

    -- Centralized Companies Table (Logistics & Production)
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_companies (
            id INT NOT NULL AUTO_INCREMENT,
            citizenid VARCHAR(50) NOT NULL,
            name VARCHAR(80) NOT NULL DEFAULT 'Nova Empresa',
            level INT DEFAULT 1,
            experience INT DEFAULT 0,
            vault_balance BIGINT NOT NULL DEFAULT 0,
            warehouse_id INT DEFAULT NULL,
            upgrades LONGTEXT DEFAULT NULL,
            is_active TINYINT(1) DEFAULT 1,
            in_debt_since TIMESTAMP NULL DEFAULT NULL,
            foreclosed_at TIMESTAMP NULL DEFAULT NULL,
            primary_product VARCHAR(50) DEFAULT NULL,
            secondary_product VARCHAR(50) DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY (citizenid)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Ensure backward compatibility with all fields
    MySQL.query.await([[
        ALTER TABLE `tycoon_companies` 
        ADD COLUMN IF NOT EXISTS `experience` INT DEFAULT 0 AFTER `level`,
        ADD COLUMN IF NOT EXISTS `vault_balance` BIGINT NOT NULL DEFAULT 0 AFTER `experience`,
        ADD COLUMN IF NOT EXISTS `warehouse_id` INT DEFAULT NULL AFTER `vault_balance`,
        ADD COLUMN IF NOT EXISTS `upgrades` LONGTEXT DEFAULT NULL AFTER `warehouse_id`,
        ADD COLUMN IF NOT EXISTS `is_active` TINYINT(1) DEFAULT 1 AFTER `upgrades`,
        ADD COLUMN IF NOT EXISTS `in_debt_since` TIMESTAMP NULL DEFAULT NULL AFTER `is_active`,
        ADD COLUMN IF NOT EXISTS `foreclosed_at` TIMESTAMP NULL DEFAULT NULL AFTER `in_debt_since`,
        ADD COLUMN IF NOT EXISTS `primary_product` VARCHAR(50) DEFAULT NULL AFTER `foreclosed_at`,
        ADD COLUMN IF NOT EXISTS `secondary_product` VARCHAR(50) DEFAULT NULL AFTER `primary_product`,
        ADD COLUMN IF NOT EXISTS `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`;
    ]])
end

-- ==========================================
-- SECURITY: Internal Auth
-- ==========================================
local function isAuthorized()
    local invoking = GetInvokingResource()
    if not invoking or invoking == GetCurrentResourceName() or invoking == 'ox_lib' then return true end
    if string.find(invoking, config.AuthorizedResourcePrefix) then return true end
    print(("^1[Tycoon:Core:Security]^7 Recurso '%s' tentou acesso restrito!"):format(invoking))
    return false
end

-- ==========================================
-- SEGMENTED SYNC
-- ==========================================
local function syncPlayerState(source, profile)
    if not profile then return end
    local state = Player(source).state
    state:set('tycoon:stats', {
        companyName = profile.companyName,
        level = profile.level,
        experience = profile.experience,
        maxExperience = profile.maxExperience,
        reputation = profile.reputation,
        isSuspended = profile.isSuspended
    }, true)
    state:set('tycoon:skills', profile.skills, true)
    state:set('tycoon:tutorial', profile.tutorial, true)
    state:set('tycoon:licenses', profile.licenses, true)
    state:set('tycoonProfile', profile, true)
end

-- ==========================================
-- PROFILE ENGINE
-- ==========================================

local function generateUniquePlate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local plate
    local exists = true
    while exists do
        plate = ""
        for i = 1, 8 do
            local rand = math.random(1, #chars)
            plate = plate .. string.sub(chars, rand, rand)
        end
        local result = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
        if not result then
            exists = false
        end
    end
    return plate
end

local function getPlayerProfile(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return nil end
    if PlayerProfiles[citizenId] then return PlayerProfiles[citizenId] end

    local row = MySQL.single.await('SELECT * FROM tycoon_players WHERE citizenid = ?', { citizenId })
    if not row then
        local skills = json.encode(config.SkillDefaults)
        local upgrades = json.encode(config.UpgradeDefaults)
        local licenses = json.encode({ driver = true, truck = false, heli = false, pilot = false })

        MySQL.insert.await([[
            INSERT INTO tycoon_players (citizenid, level, experience, reputation, licenses, skills, upgrades)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], { citizenId, 1, 0, 0, licenses, skills, upgrades })

        -- Grant starter vehicle (Faggio) in motelgarage (Protected and logged)
        local success, err = pcall(function()
            local license = player and player.PlayerData and player.PlayerData.license or nil
            local plate = generateUniquePlate()
            local hash = GetHashKey('faggio')
            local mods = json.encode({ plate = plate, engineHealth = 1000.0, bodyHealth = 1000.0, fuelLevel = 100.0, model = 'faggio' })
            MySQL.insert.await([[
                INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, type)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], { license, citizenId, 'faggio', hash, mods, plate, 'motelgarage', 1, 'car' })
            print(("^2[Tycoon:Core]^7 Faggio inicial criada no banco para o citizenid %s com placa %s"):format(citizenId, plate))
        end)
        if not success then
            local errMsg = tostring(err)
            print(("^1[Tycoon:Core:Error]^7 Falha ao criar veiculo inicial no banco: %s"):format(errMsg))
            TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 0, 0 },
                multiline = true,
                args = { "Tycoon:Core:Error", "Falha ao criar Faggio: " .. errMsg }
            })
            exports.cidade_tycoon_core:NotifyPlayer(source, 'Erro ao criar Faggio: ' .. string.sub(errMsg, 1, 60), 'error')
        end

        -- Grant starter items and cash (Protected against race conditions during early player loading)
        pcall(function()
            exports.cidade_tycoon_core:AddMoney(source, 'bank', 5000, 'tycoon-start-bonus')
        end)
        pcall(function()
            exports.cidade_tycoon_core:EnsureStarterItem(source, 'tablet', 1)
        end)
        pcall(function()
            exports.cidade_tycoon_core:NotifyPlayer(source, 'Bem-vindo ao Tycoon! Você recebeu uma Scooter Faggio na Garagem Inicial, o Tablet e $5000.', 'success')
        end)

        row = {
            citizenid = citizenId, company_name = config.DefaultCompany,
            level = 1, experience = 0, reputation = 0,
            licenses = licenses, skills = skills, upgrades = upgrades,
            vault_balance = 0, is_suspended = 0, tutorial_current_step = 'welcome'
        }
    end

    local profile = {
        citizenid = row.citizenid,
        companyName = row.company_name or config.DefaultCompany,
        level = row.level or 1,
        experience = row.experience or 0,
        maxExperience = (row.level or 1) * config.ExperiencePerLevel,
        reputation = row.reputation or 0,
        reputationProduction = row.reputation_production or 0,
        reputationFiscal = row.reputation_fiscal or 0,
        vaultBalance = row.vault_balance or 0,
        isSuspended = (row.is_suspended == 1),
        licenses = row.licenses and json.decode(row.licenses) or { driver = true },
        skills = row.skills and json.decode(row.skills) or config.SkillDefaults,
        upgrades = row.upgrades and json.decode(row.upgrades) or config.UpgradeDefaults,
        tutorial = {
            currentStep = row.tutorial_current_step or 'welcome',
            active = (row.tutorial_completed_at == nil)
        }
    }

    -- Resiliently enrich profile with company ownership data
    local hasCompany = false
    local companyWarehouseId = nil
    pcall(function()
        local companyRow = MySQL.single.await('SELECT id, name, warehouse_id FROM tycoon_companies WHERE citizenid = ?', { citizenId })
        if companyRow then
            hasCompany = true
            companyWarehouseId = companyRow.warehouse_id
            profile.companyName = companyRow.name
        end
    end)
    profile.hasCompany = hasCompany
    profile.companyWarehouseId = companyWarehouseId

    PlayerProfiles[citizenId] = profile
    syncPlayerState(source, profile)
    return profile
end

-- ==========================================
-- EXPORTS
-- ==========================================

local function addExperience(source, amount)
    if not isAuthorized() then return false end
    
    local profile = getPlayerProfile(source)
    if not profile then return false end

    local xp = tonumber(amount) or 0
    if xp <= 0 then return false end

    profile.experience = profile.experience + xp

    local maxExp = profile.maxExperience
    local leveledUp = false

    while profile.experience >= maxExp do
        profile.level = profile.level + 1
        profile.experience = profile.experience - maxExp
        profile.maxExperience = profile.level * config.ExperiencePerLevel
        maxExp = profile.maxExperience
        leveledUp = true
    end

    MySQL.update.await('UPDATE tycoon_players SET level = ?, experience = ? WHERE citizenid = ?', { profile.level, profile.experience, profile.citizenid })
    syncPlayerState(source, profile)

    if leveledUp then
        exports.cidade_tycoon_core:NotifyPlayer(source, ('Você alcançou o Nível %d!'):format(profile.level), 'success')
    end

    return true
end
exports('AddExperience', addExperience)

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res then return end
    createTycoonTables()

    -- Structural Database Diagnostic for player_vehicles
    CreateThread(function()
        Wait(2000)
        local success, result = pcall(function()
            return MySQL.query.await("DESCRIBE player_vehicles")
        end)
        if success and result then
            print("^3[Tycoon:Core:DB_Diag] Estrutura real de player_vehicles no Banco:^7")
            for _, col in ipairs(result) do
                print(("- Coluna: '%s' | Tipo: %s | Permite Null: %s | Chave: %s | Default: %s"):format(
                    tostring(col.Field or col.Column),
                    tostring(col.Type),
                    tostring(col.Null),
                    tostring(col.Key),
                    tostring(col.Default)
                ))
            end
        else
            print("^1[Tycoon:Core:DB_Diag:Error] Falha ao ler estrutura de player_vehicles:^7", tostring(result))
        end
    end)
end)

AddEventHandler('qbx_core:server:onPlayerLoaded', function(source) getPlayerProfile(source) end)

exports('GetPlayerProfile', getPlayerProfile)
exports('UpdateTutorialStep', function(source, step)
    local profile = getPlayerProfile(source)
    if profile then
        profile.tutorial.currentStep = step
        MySQL.update('UPDATE tycoon_players SET tutorial_current_step = ? WHERE citizenid = ?', { step, profile.citizenid })
        syncPlayerState(source, profile)
        return true
    end
    return false
end)

exports('ClearProfileCache', function(cid) PlayerProfiles[cid] = nil end)

-- Update a specific database field on tycoon_players
exports('UpdateProfileField', function(source, field, value)
    if not source or not field then return false end
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile or not profile.citizenid then return false end

    -- Whitelist of allowed fields for security
    local allowedFields = {
        active_plate = true,
        is_suspended = true,
        reputation_fiscal = true,
        hybrid_score = true,
        company_name = true,
        tax_streak = true,
    }

    if not allowedFields[field] then
        print(('^1[Tycoon:Core:Security]^7 Tentativa de atualizar campo nao autorizado: %s'):format(field))
        return false
    end

    local success = MySQL.update.await(('UPDATE tycoon_players SET %s = ? WHERE citizenid = ?'):format(field), { value, profile.citizenid })
    if success then
        -- Update in-memory profile if it exists
        profile[field] = value
        syncPlayerState(source, profile)
        return true
    end
    return false
end)

-- ==========================================
-- TYCOON MODIFICATION EXPORTS
-- ==========================================

local function updateSkills(source, skillsTable)
    local profile = getPlayerProfile(source)
    if profile then
        profile.skills = skillsTable
        MySQL.update.await('UPDATE tycoon_players SET skills = ? WHERE citizenid = ?', { json.encode(skillsTable), profile.citizenid })
        syncPlayerState(source, profile)
        return true
    end
    return false
end
exports('UpdateSkills', updateSkills)

local function setLevel(source, level)
    local profile = getPlayerProfile(source)
    if profile then
        profile.level = tonumber(level) or 1
        profile.experience = 0
        profile.maxExperience = profile.level * config.ExperiencePerLevel
        MySQL.update.await('UPDATE tycoon_players SET level = ?, experience = ? WHERE citizenid = ?', { profile.level, profile.experience, profile.citizenid })
        syncPlayerState(source, profile)
        return true
    end
    return false
end
exports('SetLevel', setLevel)

local function resetProfile(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(source)
    if not citizenId then return false end

    local licenses = {}
    local skills = config.SkillDefaults
    local upgrades = {}

    local profile = {
        citizenid = citizenId,
        level = 1,
        experience = 0,
        maxExperience = config.ExperiencePerLevel,
        reputation = 0,
        licenses = licenses,
        skills = skills,
        upgrades = upgrades,
        isSuspended = false,
        taxStreak = 0,
        reputationFiscal = 0,
        hybridScore = 100,
        activePlate = nil,
        hasCompany = false,
        companyName = nil,
        companyWarehouseId = nil
    }

    MySQL.update.await([[
        UPDATE tycoon_players 
        SET level = 1, experience = 0, reputation = 0, licenses = ?, skills = ?, upgrades = ?, is_suspended = 0, tax_streak = 0, reputation_fiscal = 0, hybrid_score = 100, active_plate = NULL
        WHERE citizenid = ?
    ]], { json.encode(licenses), json.encode(skills), json.encode(upgrades), citizenId })

    PlayerProfiles[citizenId] = profile
    syncPlayerState(source, profile)
    return true
end
exports('ResetProfile', resetProfile)

local function syncPlayerStateExport(source)
    local profile = getPlayerProfile(source)
    if profile then
        syncPlayerState(source, profile)
        return true
    end
    return false
end
exports('SyncPlayerState', syncPlayerStateExport)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for cid, profile in pairs(PlayerProfiles) do
        MySQL.update.await('UPDATE tycoon_players SET level = ?, experience = ? WHERE citizenid = ?', { profile.level, profile.experience, cid })
    end
end)
