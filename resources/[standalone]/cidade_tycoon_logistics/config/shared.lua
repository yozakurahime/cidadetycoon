Config = {}

Config.SimulationTick = 5000 
Config.DBFlushInterval = 60000 
Config.GracePeriodDays = 7      

Config.ManagerDefaults = {
    dailyWithdrawLimit = 5000,
    canHire = true,
    canFire = false,
    canPostJobs = true
}

Config.EmployeeTraits = {
    { key = 'expert', label = 'Perito', description = 'Reduz custos operacionais em 15%.', effect = { costMult = 0.85 } },
    { key = 'reckless', label = 'Apressado', description = 'Entrega 20% mais rápido, mas 10% chance de dano.', effect = { speedMult = 1.2, risk = 0.1 } },
    { key = 'careful', label = 'Cuidadoso', description = 'Nunca danifica a carga, mas 15% mais lento.', effect = { speedMult = 0.85, risk = 0.0 } },
    { key = 'standard', label = 'Padrão', description = 'Motorista sem especialidade definida.', effect = { speedMult = 1.0, risk = 0.02 } }
}

Config.JobBoard = {
    expireHours = 48,
    minReward = 2000
}

-- ==========================================
-- WAREHOUSES & LOGISTICS CENTERS
-- ==========================================
Config.warehouses = {
    [1] = {
        name = 'PostOP Hub (LS)',
        coords = vec4(1194.2, -3107.5, 6.0, 90.0),
        productionCoords = vec3(1200.0, -3112.0, 6.0),
        autopartsCoords = vec3(1190.0, -3110.0, 6.0)
    },
    [2] = {
        name = 'The Foundry (Cypress Flats)',
        coords = vec4(1088.1, -1998.6, 31.0, 180.0),
        productionCoords = vec3(1095.0, -2005.0, 31.0),
        autopartsCoords = vec3(1080.0, -2000.0, 31.0)
    },
    [3] = {
        name = 'Paleto Bay Logistics',
        coords = vec4(-105.0, 6340.5, 31.5, 45.0),
        productionCoords = vec3(-100.0, 6345.0, 31.5),
        autopartsCoords = vec3(-110.0, 6335.0, 31.5)
    }
}

-- ==========================================
-- PRODUCTION DEFINITIONS
-- ==========================================

Config.Production = {
    Materials = {
        ['raw_metal'] = { label = 'Metal Bruto', price = 150, weight = 1.0 },
        ['raw_electronics'] = { label = 'Componentes Eletrônicos', price = 450, weight = 0.2 },
        ['raw_rubber'] = { label = 'Borracha Bruta', price = 80, weight = 1.5 },
    },
    Recipes = {
        ['engine_block'] = {
            label = 'Bloco de Motor Industrial',
            inputs = { ['raw_metal'] = 20, ['raw_electronics'] = 5 },
            time = 300, -- 5 mins
            xp = 250,
            category = 'engine',
            outputAmount = 1,
            weight = 50.0
        },
        ['truck_tire'] = {
            label = 'Pneu de Carga Reforçado',
            inputs = { ['raw_rubber'] = 15, ['raw_metal'] = 2 },
            time = 180, -- 3 mins
            xp = 120,
            category = 'tires',
            outputAmount = 1,
            weight = 25.0
        },
        ['basic_repair_kit'] = {
            label = 'Kit de Manutenção Básica',
            inputs = { ['raw_metal'] = 5, ['raw_electronics'] = 2, ['raw_rubber'] = 2 },
            time = 120, -- 2 mins
            xp = 80,
            category = 'misc',
            outputAmount = 1,
            weight = 5.0
        }
    }
}

return Config
