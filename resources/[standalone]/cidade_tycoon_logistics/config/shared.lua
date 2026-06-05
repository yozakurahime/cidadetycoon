local config = {}

config.warehouses = {
    [1] = {
        name = 'Sede Porto de LS (PostOP)',
        coords = vec4(1196.5, -3250.8, 7.1, 90.0),
        productionCoords = vec3(1202.0, -3258.0, 7.1),
        price = 350000,
        capacity = 100,
    },
    [2] = {
        name = 'Sede Cypress Flats (Centro)',
        coords = vec4(832.5, -2105.2, 30.5, 0.0),
        productionCoords = vec3(835.0, -2110.0, 30.5),
        price = 220000,
        capacity = 50,
    },
    [3] = {
        name = 'Sede Elysian Island',
        coords = vec4(153.9, -3211.7, 5.9, 270.0),
        productionCoords = vec3(150.0, -3215.0, 5.9),
        price = 350000,
        capacity = 80,
    },
    [4] = {
        name = 'Sede Terminal Central',
        coords = vec4(1200.0, -1275.0, 35.2, 90.0),
        productionCoords = vec3(1195.0, -1270.0, 35.2),
        price = 420000,
        capacity = 150,
    },
    [5] = {
        name = 'Sede Grapeseed (Farm Shed)',
        coords = vec4(1694.5, 4896.2, 42.1, 0.0),
        productionCoords = vec3(1705.0, 4902.0, 42.1),
        price = 500000,
        capacity = 300,
    },
    [6] = {
        name = 'Sede Sandy Shores',
        coords = vec4(1960.0, 3745.0, 32.3, 130.0),
        productionCoords = vec3(1965.0, 3750.0, 32.3),
        price = 600000,
        capacity = 200,
    },
    [7] = {
        name = 'Sede Paleto Bay',
        coords = vec4(2678.0, 3288.0, 55.2, 45.0),
        productionCoords = vec3(2670.0, 3295.0, 55.2),
        price = 1200000,
        capacity = 500,
    }
}

config.npcRecruitment = {
    baseCost = 5000,
    levels = {
        [1] = { label = 'Iniciante', multiplier = 1.0, salary = 500 },
        [2] = { label = 'Profissional', multiplier = 1.2, salary = 850 },
        [3] = { label = 'Especialista', multiplier = 1.5, salary = 1500 },
    }
}

config.production = {
    materials = {
        ['raw_electronics'] = { label = 'Componentes Eletrônicos', price = 45 },
        ['raw_food'] = { label = 'Insumos Alimentícios', price = 12 },
        ['raw_fuel'] = { label = 'Combustível Bruto', price = 25 },
        ['raw_metal'] = { label = 'Minério de Metal', price = 18 },
        ['chemicals'] = { label = 'Produtos Químicos', price = 30 },
    },
    recipes = {
        ['electronics_crate'] = {
            label = 'Caixa de Eletrônicos',
            category = 'Valiosos',
            inputs = { ['raw_electronics'] = 10, ['raw_metal'] = 5 },
            outputKey = 'electronics_crate',
            outputAmount = 1,
            time = 300, -- 5 mins
            xp = 150
        },
        ['packaged_food'] = {
            label = 'Grade de Alimentos',
            category = 'Perecíveis',
            inputs = { ['raw_food'] = 20, ['chemicals'] = 2 },
            outputKey = 'packaged_food',
            outputAmount = 1,
            time = 180, -- 3 mins
            xp = 80
        },
        ['processed_fuel'] = {
            label = 'Barril de Combustível',
            category = 'Perigosa',
            inputs = { ['raw_fuel'] = 15, ['chemicals'] = 5 },
            outputKey = 'processed_fuel',
            outputAmount = 1,
            time = 420, -- 7 mins
            xp = 250
        },
        ['high_end_parts'] = {
            label = 'Peças de Alta Precisão',
            category = 'Mecânica',
            inputs = { ['raw_electronics'] = 15, ['raw_metal'] = 20 },
            outputKey = 'high_end_parts',
            outputAmount = 1,
            time = 600, -- 10 mins
            xp = 400
        }
    }
}

return config
