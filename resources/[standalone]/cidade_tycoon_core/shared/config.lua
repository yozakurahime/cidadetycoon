TycoonCore = TycoonCore or {}

TycoonCore.Config = {
    skillDefaults = {
        skill_fragile = 0,
        skill_heavy = 0,
        skill_hazardous = 0,
        skill_long_distance = 0,
        skill_logistics = 0,
    },

    upgradeDefaults = {
        fleet_tier = 0,
        capacity_boost = 0,
        efficiency_tuning = 0,
        vehicle_performance = 0,
        vehicle_handling = 0,
        cargo_capacity = 0,
    },

    recoveryFeeConfig = {
        baseFee = 500,
        tierMultipliers = {
            [0] = 1.0,  -- $500 (Bikes/Starters)
            [1] = 1.5,  -- $750 (Cars/Light)
            [2] = 2.5,  -- $1250 (Mid/SUV)
            [3] = 4.0,  -- $2000 (Premium/Work T3)
            [4] = 7.0,  -- $3500 (Trucks T4)
            [5] = 12.0, -- $6000 (Heavy Trucks T5/Status Super)
            [6] = 25.0, -- $12500 (Hypercars)
        }
    },

    licenseDefinitions = {
        { key = 'logistica_basica', label = 'Licença Logística Básica', requiredReputation = 0, cost = 8000 },
        { key = 'truck', label = 'Habilitação Categoria C (Caminhões)', requiredReputation = 120, cost = 18000 },
        { key = 'heli', label = 'Licença de Piloto de Helicóptero', requiredReputation = 240, cost = 28000 },
        { key = 'pilot', label = 'Licença de Piloto Comercial', requiredReputation = 400, cost = 42000 },
    },

    experiencePerLevel = 1500,
    maxLevel = 100,
}

return TycoonCore.Config
