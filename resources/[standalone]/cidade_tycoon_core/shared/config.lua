local Config = {}

-- ==========================================
-- SYSTEM CONFIGURATION
-- ==========================================
Config.MaxLevel = 100
Config.ExperiencePerLevel = 1500
Config.DefaultCompany = 'Transportes Tycoon'
Config.isDebug = false -- Set true to enable verbose debug logging

Config.LogBufferCap = 1000
Config.LogFlushInterval = 10000 -- 10 seconds

-- Allowed prefixes for core exports
Config.AuthorizedResourcePrefix = 'cidade_'

-- ==========================================
-- CORE DEFINITIONS
-- ==========================================

Config.LicenseDefinitions = {
    { key = 'driver', label = 'Habilitação Categoria B (Leve)', cost = 0, requiredReputation = 0 },
    { key = 'truck', label = 'Habilitação Categoria C (Caminhões)', cost = 15000, requiredReputation = 200 },
    { key = 'heli', label = 'Habilitação Categoria H (Helicópteros)', cost = 150000, requiredReputation = 800 },
    { key = 'pilot', label = 'Habilitação Categoria P (Aviões)', cost = 500000, requiredReputation = 1500 }
}

Config.SkillDefaults = {
    skill_logistics = 0,
    skill_long_distance = 0,
    skill_fragile = 0,
    skill_valuable = 0,
    skill_hazardous = 0
}

Config.UpgradeDefaults = {
    warehouse_slots = 0,
    fleet_size = 2,
    mechanic_efficiency = 0
}

Config.recoveryFeeConfig = {
    baseFee = 5000,
    tierMultipliers = {
        [0] = 0.5,
        [1] = 1.0,
        [2] = 1.5,
        [3] = 2.5,
        [4] = 4.0,
        [5] = 6.0
    }
}

-- Tax and finance configuration
Config.taxConfig = {
    intervalDays = 7,
    hubTaxRate = 0.02, -- 2% do valor de compra
    ipvaPopular = 500,
    ipvaLuxo = 15000,
    suspensionCheckInterval = 30, -- minutos
}

-- Skill training configuration
Config.skillTraining = {
    maxLevel = 5,
    baseCost = 500, -- cost = (currentLevel + 1) * baseCost
}

-- Maintenance workshop configuration
Config.workshop = {
    laborFeeRate = 0.3, -- 30% do preço do veículo
    minLaborFee = 1000,
    maxLaborFee = 15000,
    luxuryMultiplier = 10,
    freeTierMaxLevel = 5,
}

-- Electric vehicle models configuration
Config.ElectricVehicles = {
    ['neon'] = true, ['voltic'] = true, ['tezeract'] = true, ['cyclone'] = true, ['raiden'] = true,
    ['surge'] = true, ['dilettante'] = true, ['khamelion'] = true, ['imorgon'] = true,
    ['iwagen'] = true, ['everon'] = true, ['futurism'] = true,
    ['taycan'] = true, ['models'] = true, ['p90d'] = true, ['teslapd'] = true,
}

-- Electric vehicle performance tuning by vehicle class
-- Higher class EVs get more aggressive acceleration (instant torque)
Config.EVPerformance = {
    [7] = { driveMult = 1.65, speedCap = 0.92, tractionReduction = 0.85, label = 'Hyper EV' },     -- tezeract, cyclone, imorgon
    [6] = { driveMult = 1.55, speedCap = 0.95, tractionReduction = 0.88, label = 'Sports EV' },    -- neon, raiden, khamelion
    [1] = { driveMult = 1.48, speedCap = 1.0, tractionReduction = 0.92, label = 'Sedan EV' },      -- surge, taycan, models
    [0] = { driveMult = 1.35, speedCap = 1.02, tractionReduction = 0.96, label = 'Economy EV' },   -- dilettante
    default = { driveMult = 1.40, speedCap = 1.0, tractionReduction = 0.94, label = 'Standard EV' },
}

return Config
