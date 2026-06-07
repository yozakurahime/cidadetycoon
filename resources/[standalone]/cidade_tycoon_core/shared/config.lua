Config = {}

-- ==========================================
-- SYSTEM CONFIGURATION
-- ==========================================
Config.MaxLevel = 100
Config.ExperiencePerLevel = 1500
Config.DefaultCompany = 'Transportes Tycoon'

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

return Config
