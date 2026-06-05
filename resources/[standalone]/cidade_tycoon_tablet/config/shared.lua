local config = {}

config.companyPurchase = {
    price = 250000,
    interactionDistance = 2.2,
    serverValidationDistance = 8.0,
    points = {}
}

config.freelance = {
    interactionDistance = 2.2,
    serverValidationDistance = 10.0,
    deliveryRadius = 9.0,
    minimumMissionDistance = 450.0,
    points = {
        land = {},
        water = {},
        air = {},
    },
    vehiclePools = {
        land = {
            { model = 'honcrx91', requiredFleetTier = 1 },
            { model = '17civict', requiredFleetTier = 1 },
            { model = '09tahoe', requiredFleetTier = 2 },
            { model = 'bison', requiredFleetTier = 2 },
            { model = 'ram2500', requiredFleetTier = 2 },
            { model = 'vxr', requiredFleetTier = 3 },
            { model = 'mule', requiredFleetTier = 4 },
            { model = 'pounder', requiredFleetTier = 5 },
            { model = 'barracks', requiredFleetTier = 5 },
        },
        water = {
            { model = 'dinghy', requiredFleetTier = 5 },
            { model = 'suntrap', requiredFleetTier = 6 },
            { model = 'marquis', requiredFleetTier = 7 },
            { model = 'tug', requiredFleetTier = 8 },
        },
        air = {
            { model = 'maverick', requiredFleetTier = 6 },
            { model = 'frogger', requiredFleetTier = 7 },
            { model = 'swift', requiredFleetTier = 8 },
            { model = 'cargobob', requiredFleetTier = 9 },
        },
    },
    baseRewards = {
        land = 4500,
        water = 5600,
        air = 8000,
    },
    baseRewardPerBox = {
        land = 1500,
        water = 2800,
        air = 4000,
    }
}

config.deliveryRoutes = {
    land = {},
    water = {
        vec3(-798.21, -1502.88, 1.59),
        vec3(-728.64, -1327.19, 1.60),
        vec3(-3407.54, 955.68, 8.35),
        vec3(-1596.43, 5262.64, 3.97),
        vec3(3863.30, 4463.52, 2.73),
        vec3(1298.51, 4239.41, 33.91),
        vec3(1334.46, 4264.08, 30.18),
        vec3(-1852.30, -1231.86, 1.00),
        vec3(-2144.79, -389.74, 1.00),
        vec3(3095.82, -4802.03, 2.51),
        vec3(-102.21, -2659.47, 6.00),
        vec3(270.58, -3017.44, 5.79),
        vec3(1208.94, -2975.53, 5.87),
        vec3(3835.33, 4447.60, 2.80),
    },
    air = {
        vec3(-1032.87, -2730.61, 13.76),
        vec3(-1145.22, -2864.72, 13.95),
        vec3(1723.44, 3288.05, 41.15),
        vec3(1770.08, 3239.63, 42.13),
        vec3(2120.92, 4805.87, 41.20),
        vec3(-67.89, -801.21, 44.23),
        vec3(-745.90, -1468.63, 5.00),
        vec3(-1267.65, -3379.41, 13.94),
        vec3(449.12, -981.24, 43.69),
        vec3(1848.77, 2590.09, 45.67),
        vec3(3134.35, -1465.43, 46.50),
    }
}

config.hubs = {
    {
        id = 1,
        name = "Porto de Los Santos - Transportes",
        coords = vec4(154.0, -3212.0, 5.9, 270.0),
        pedModel = "s_m_m_trucker_01",
        modes = { land = true, water = true },
        spawnCoords = {
            land = vec4(164.0, -3220.0, 5.9, 90.0),
            water = vec4(255.0, -3004.0, 5.8, 180.0),
        }
    },
    {
        id = 2,
        name = "La Mesa - Logistica",
        coords = vec4(730.0, -1088.0, 22.2, 180.0),
        pedModel = "s_m_m_dockwork_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(733.0, -1079.0, 22.2, 270.0),
        }
    },
    {
        id = 3,
        name = "Elysian Island - Marina & Cargas",
        coords = vec4(1177.0, -3304.0, 5.9, 0.0),
        pedModel = "s_m_m_dockwork_01",
        modes = { land = true, water = true },
        spawnCoords = {
            land = vec4(1195.0, -3265.0, 5.9, 90.0),
            water = vec4(1298.51, 4239.41, 30.18, 0.0),
        }
    },
    {
        id = 4,
        name = "Terminal - Armazem Central",
        coords = vec4(1200.0, -1275.0, 35.2, 90.0),
        pedModel = "s_m_m_trucker_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(1218.0, -1269.0, 35.2, 180.0),
        }
    },
    {
        id = 5,
        name = "Grapeseed - Armazem Norte",
        coords = vec4(1700.0, 4920.0, 42.1, 270.0),
        pedModel = "s_m_m_trucker_01",
        modes = { land = true, air = true },
        spawnCoords = {
            land = vec4(1694.0, 4908.0, 42.1, 0.0),
            air = vec4(1690.0, 4935.0, 42.1, 90.0),
        }
    },
    {
        id = 6,
        name = "Sandy Shores - Aerodromo & Cargas",
        coords = vec4(1960.0, 3745.0, 32.3, 130.0),
        pedModel = "s_m_y_garbage",
        modes = { land = true, air = true },
        spawnCoords = {
            land = vec4(1943.0, 3754.0, 32.2, 220.0),
            air = vec4(1955.0, 3720.0, 32.2, 130.0),
        }
    },
    {
        id = 7,
        name = "Paleto Bay - Logistica Global",
        coords = vec4(2678.0, 3288.0, 55.2, 45.0),
        pedModel = "s_m_m_trucker_01",
        modes = { land = true, water = true, air = true },
        spawnCoords = {
            land = vec4(2686.0, 3265.0, 55.2, 135.0),
            water = vec4(-1596.43, 5262.64, 3.97, 180.0),
            air = vec4(2690.0, 3300.0, 55.2, 90.0),
        }
    },
    {
        id = 8,
        name = "Strawberry - Distribuidora",
        coords = vec4(-43.0, -1748.0, 29.4, 320.0),
        pedModel = "s_m_y_dockwork_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-57.0, -1758.0, 29.4, 140.0),
        }
    },
    {
        id = 9,
        name = "Rancho - Transportadora",
        coords = vec4(-716.0, -914.0, 19.2, 180.0),
        pedModel = "s_m_m_trucker_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-704.0, -931.0, 19.0, 270.0),
        }
    },
    {
        id = 10,
        name = "Burton - Entreposto",
        coords = vec4(-1230.0, -903.0, 12.3, 0.0),
        pedModel = "s_m_m_dockwork_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-1221.0, -884.0, 12.1, 90.0),
        }
    },
    {
        id = 11,
        name = "Vinewood Hills - Logistica Executiva",
        coords = vec4(-1822.0, 792.0, 138.1, 90.0),
        pedModel = "s_m_m_fiboffice_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-1835.0, 788.0, 138.0, 270.0),
        }
    },
    {
        id = 12,
        name = "Chumash - Cargas Maritimas",
        coords = vec4(-3047.0, 589.0, 7.9, 210.0),
        pedModel = "s_m_m_dockwork_01",
        modes = { land = true, water = true },
        spawnCoords = {
            land = vec4(-3054.1, 589.7, 7.9, 300.0),
            water = vec4(-3407.54, 955.68, 8.35, 180.0),
        }
    },
    {
        id = 13,
        name = "Ammunation Plaza - Logística",
        coords = vec4(22.56, -1109.89, 29.80, 160.0),
        pedModel = "s_m_y_ammucity_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(12.0, -1115.0, 29.8, 180.0),
        }
    },
    {
        id = 14,
        name = "Ammunation Sandy - Logística",
        coords = vec4(1693.44, 3760.16, 34.71, 227.0),
        pedModel = "s_m_y_ammucity_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(1690.0, 3745.0, 34.7, 227.0),
        }
    },
    {
        id = 15,
        name = "Ammunation Paleto - Logística",
        coords = vec4(-330.24, 6083.88, 31.45, 225.0),
        pedModel = "s_m_y_ammucity_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-333.0, 6065.0, 31.4, 225.0),
        }
    },
    {
        id = 16,
        name = "Supermercado 24/7 - Strawberry",
        coords = vec4(25.7, -1347.3, 29.49, 180.0),
        pedModel = "s_f_m_shop_high",
        modes = { land = true },
        spawnCoords = {
            land = vec4(26.0, -1335.0, 29.4, 270.0),
        }
    },
    {
        id = 17,
        name = "Supermercado 24/7 - Sandy Shores",
        coords = vec4(1961.48, 3739.96, 32.34, 120.0),
        pedModel = "s_f_m_shop_high",
        modes = { land = true },
        spawnCoords = {
            land = vec4(1960.0, 3750.0, 32.3, 120.0),
        }
    },
    {
        id = 18,
        name = "Supermercado 24/7 - Paleto Bay",
        coords = vec4(2679.25, 3280.12, 55.24, 330.0),
        pedModel = "s_f_m_shop_high",
        modes = { land = true },
        spawnCoords = {
            land = vec4(2683.0, 3290.0, 55.2, 330.0),
        }
    },
    {
        id = 19,
        name = "Posto de Combustível - Strawberry",
        coords = vec4(-71.28, -1761.16, 29.48, 90.0),
        pedModel = "s_m_y_garbage",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-60.0, -1770.0, 28.5, 90.0),
        }
    },
    {
        id = 20,
        name = "Posto de Combustível - Sandy Shores",
        coords = vec4(2680.01, 3265.0, 55.24, 180.0),
        pedModel = "s_m_y_garbage",
        modes = { land = true },
        spawnCoords = {
            land = vec4(2674.0, 3250.0, 55.2, 180.0),
        }
    },
    {
        id = 21,
        name = "Posto de Combustível - Paleto Bay",
        coords = vec4(-93.98, 6420.1, 31.48, 270.0),
        pedModel = "s_m_y_garbage",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-105.0, 6405.0, 31.4, 270.0),
        }
    },
    {
        id = 22,
        name = "Oficina Mecânica - Burton",
        coords = vec4(-344.36, -121.92, 38.60, 120.0),
        pedModel = "s_m_y_xmech_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-332.0, -132.0, 38.6, 120.0),
        }
    },
    {
        id = 23,
        name = "Oficina Mecânica - Sandy Shores",
        coords = vec4(1172.12, 2644.76, 38.55, 90.0),
        pedModel = "s_m_y_xmech_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(1178.6, 2639.2, 38.5, 90.0),
        }
    },
    {
        id = 24,
        name = "Oficina Mecânica - Paleto Bay",
        coords = vec4(115.55, 6625.32, 31.75, 0.0),
        pedModel = "s_m_y_xmech_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(110.4, 6631.6, 31.7, 0.0),
        }
    },
    {
        id = 25,
        name = "Vanilla Unicorn - Bar",
        coords = vec4(129.0, -1298.0, 29.0, 180.0),
        pedModel = "s_f_y_stripper_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(128.0, -1290.0, 29.0, 180.0),
        }
    },
    {
        id = 26,
        name = "Yellow Jack - Bar",
        coords = vec4(1984.0, 3054.0, 47.0, 0.0),
        pedModel = "s_m_m_barman_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(1995.0, 3065.0, 47.0, 0.0),
        }
    },
    {
        id = 27,
        name = "Bar de Paleto Bay",
        coords = vec4(-30.0, 6602.0, 31.0, 90.0),
        pedModel = "s_m_m_barman_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-36.0, 6592.0, 31.0, 90.0),
        }
    },
    {
        id = 28,
        name = "Loja de Roupas - Rockford Hills",
        coords = vec4(-705.5, -149.22, 37.42, 122.0),
        pedModel = "s_f_m_shop_high",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-715.0, -145.0, 37.4, 122.0),
        }
    },
    {
        id = 29,
        name = "Loja de Roupas - Sandy Shores",
        coords = vec4(615.35, 2762.72, 42.09, 170.51),
        pedModel = "s_f_m_shop_high",
        modes = { land = true },
        spawnCoords = {
            land = vec4(613.0, 2750.0, 42.0, 170.5),
        }
    },
    {
        id = 30,
        name = "Loja de Roupas - Paleto Bay",
        coords = vec4(9.22, 6515.74, 31.88, 131.27),
        pedModel = "s_f_m_shop_high",
        modes = { land = true },
        spawnCoords = {
            land = vec4(1.0, 6504.0, 31.8, 131.2),
        }
    },
    {
        id = 31,
        name = "Banco Fleeca - Legion Square",
        coords = vec4(149.46, -1042.09, 29.37, 335.43),
        pedModel = "u_m_m_bankman",
        modes = { land = true },
        spawnCoords = {
            land = vec4(146.0, -1030.0, 29.3, 335.4),
        }
    },
    {
        id = 32,
        name = "Banco Fleeca - Sandy Shores",
        coords = vec4(1174.8, 2708.2, 38.09, 178.52),
        pedModel = "u_m_m_bankman",
        modes = { land = true },
        spawnCoords = {
            land = vec4(1179.0, 2698.0, 38.0, 178.5),
        }
    },
    {
        id = 33,
        name = "Banco Fleeca - Paleto Bay",
        coords = vec4(-112.22, 6471.01, 31.63, 134.18),
        pedModel = "u_m_m_bankman",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-98.0, 6476.0, 31.6, 134.1),
        }
    },
    {
        id = 34,
        name = "Aeroporto - Los Santos (LSIA)",
        coords = vec4(-1147.0, -1990.0, 13.1, 90.0),
        pedModel = "s_m_m_armoured_01",
        modes = { land = true, air = true },
        spawnCoords = {
            land = vec4(-1139.1, -2007.1, 13.1, 90.0),
            air = vec4(-1160.0, -2020.0, 13.1, 90.0),
        }
    },
    {
        id = 35,
        name = "Aeroporto - Sandy Shores",
        coords = vec4(1731.0, 3282.0, 41.1, 80.0),
        pedModel = "s_m_m_armoured_01",
        modes = { land = true, air = true },
        spawnCoords = {
            land = vec4(1723.4, 3288.0, 41.1, 80.0),
            air = vec4(1770.08, 3239.63, 42.13, 80.0),
        }
    },
    {
        id = 36,
        name = "Aeroporto - Grapeseed (McKenzie)",
        coords = vec4(2120.92, 4805.87, 41.20, 90.0),
        pedModel = "s_m_m_armoured_01",
        modes = { land = true, air = true },
        spawnCoords = {
            land = vec4(2135.0, 4800.0, 41.2, 90.0),
            air = vec4(2135.0, 4790.0, 41.2, 90.0),
        }
    },
    {
        id = 37,
        name = "Barbearia - Del Perro",
        coords = vec4(-1282.57, -1116.84, 6.99, 89.25),
        pedModel = "s_m_m_hairdress_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-1279.0, -1108.0, 6.9, 89.2),
        }
    },
    {
        id = 38,
        name = "Barbearia - Sandy Shores",
        coords = vec4(1931.41, 3729.73, 32.84, 212.08),
        pedModel = "s_m_m_hairdress_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(1935.0, 3722.0, 32.8, 212.0),
        }
    },
    {
        id = 39,
        name = "Barbearia - Burton",
        coords = vec4(-814.22, -183.7, 37.57, 116.91),
        pedModel = "s_m_m_hairdress_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-806.0, -177.0, 37.5, 116.9),
        }
    },
    {
        id = 40,
        name = "Estúdio de Tatuagem - Vespucci",
        coords = vec4(-1154.01, -1425.31, 4.95, 23.21),
        pedModel = "u_m_y_tattoo_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-1147.0, -1418.0, 4.9, 23.2),
        }
    },
    {
        id = 41,
        name = "Estúdio de Tatuagem - Sandy Shores",
        coords = vec4(1864.1, 3747.91, 33.03, 17.23),
        pedModel = "u_m_y_tattoo_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(1861.0, 3756.0, 33.0, 17.2),
        }
    },
    {
        id = 42,
        name = "Estúdio de Tatuagem - Paleto Bay",
        coords = vec4(-3169.52, 1074.86, 20.83, 253.29),
        pedModel = "u_m_y_tattoo_01",
        modes = { land = true },
        spawnCoords = {
            land = vec4(-3160.0, 1082.0, 20.8, 253.2),
        }
    },
}

config.freelance.capacities = {}

local function setVehicleCapacity(capacity, models)
    for i = 1, #models do
        config.freelance.capacities[tostring(models[i]):lower()] = capacity
    end
end

-- Starter / bikes
setVehicleCapacity(1, { 'cruiser', 'bmx', 'tribike', 'scorcher', 'faggio', 'katana', 'gsxr19' })

-- Core work - tier 1
setVehicleCapacity(4, {
    'honcrx91', 'srt4', '17civict', 'cam8tun', 'gs350', 'mk2100',
    'tltypes', 'is350mod', 's8d2', '16charger', 'aaq4', 'tmodel'
})

-- Core work - tier 2
setVehicleCapacity(6, { '09tahoe', 'safari97', 'bison' })
setVehicleCapacity(8, { 'ram2500', 'v250', 'f150', '15tahoe', 'nissantitan17', 'raptor2017', 'wildtrak' })

-- Core work - tier 3+
setVehicleCapacity(8, { 'xc90', 'tahoe21', 'teslax', 'q820' })
setVehicleCapacity(10, { 'vxr', 'trx', 'cesc21' })
setVehicleCapacity(12, { 'mule' })
setVehicleCapacity(16, { 'pounder' })
setVehicleCapacity(20, { 'barracks' })

-- Premium funcional
setVehicleCapacity(4, { 'lrrr', 'jeepreneg', 'jeep2012', 'rrevoque' })
setVehicleCapacity(5, { 'srt8', 'sq72016', 'pm19', 'fpacehm', 'gl63', 'trhawk', 'levante', 'p90d', 'pcs18' })
setVehicleCapacity(6, { 'rrst', 'g65', 'rsvr16', 'amdbx', 'bbentayga', 'urus' })

-- Civilian / status light
setVehicleCapacity(3, { 'miata3', 'na6', 'fto', 'svx', 'z32', '84rx7k', '180sx', 'fc3s', '80b4', 'ap2', 'sl500', 'esprit02' })
setVehicleCapacity(4, {
    'e34', 'maj350', 's14', '760li04', 'nis15', 'subwrx', 'ns350', '16challenger',
    'subisti08', 'majfd', 'nzp', 'audquattros', 'cats', 'fk8'
})

-- Race / sports
setVehicleCapacity(3, { 'sultanrs', 'elegy', 'jester', 'kuruma', 'ninef', 'comet2', 'banshee', 'massacro' })
setVehicleCapacity(4, {
    'm3e36', 'corvettec5z06', 'm3e92', 'mustang50th', 'rcf', 'toysupmk4',
    'ttrs', 'z419', 'm2', '99viper', '2020ss', 'czr1', 'm3f80', 'm4f82',
    '718caymans', 'c7', 'stingray', 'ast', 'gtr', 'gtrc', 'tr22'
})
setVehicleCapacity(5, { 'models', 'teslapd', 'chr20', 'skyline', 'm6f13', 'demon', 'taycan' })
setVehicleCapacity(6, { 'rs6', 'rs72020' })

-- Super / hyper status
setVehicleCapacity(2, { 'fct', 'wraith', 'dawnonyx', 'rculi', 'rrphantom', 'f812' })
setVehicleCapacity(1, {
    'mp412c', 'f430s', 'amggtrr20', 'r8ppi', 'yfe458i1', 'fgt', 'r820', '650s',
    'yfe458s1', '675lt', 'huracanst', 'yfe458i2', 'lp670sv', 'cgt', 'yfe458s2',
    '720s', 'lp700r', 'gt17', 'yfef12t', 'yfef12a', 'svj63', 'regalia', 'it18',
    'senna', 'lambose', 'gtr96', 'mig', 'wmfenyr', 'mcst', 'laferrari', 'lykan',
    'veneno', 'regera', 'agerars', 'fxxk', 'bolide'
})

-- Water / air
setVehicleCapacity(2, { 'dinghy', 'maverick' })
setVehicleCapacity(3, { 'suntrap', 'frogger' })
setVehicleCapacity(4, { 'swift' })
setVehicleCapacity(6, { 'marquis' })
setVehicleCapacity(8, { 'cargobob' })
setVehicleCapacity(12, { 'tug' })

function config.getVehicleCapacity(modelName)
    local name = tostring(modelName or ''):lower()
    local cap = config.freelance.capacities[name]
    if cap then
        return cap
    end

    -- Padrões com base no tipo de veículo
    if string.find(name, 'bike') or string.find(name, 'cycle') or name == 'faggio' then
        return 1
    elseif string.find(name, 'truck') or string.find(name, 'van') or name == 'speedo' or name == 'burrito' then
        return 4
    end

    return 2 -- padrão para carros normais
end

-- Concessionária e Preços Específicos das Sedes (Hubs)
local priceMatrix = {
    [1] = 350000, -- Porto
    [2] = 220000, -- La Mesa
    [3] = 350000, -- Elysian Island
    [4] = 420000, -- Terminal
    [5] = 500000, -- Grapeseed
    [6] = 600000, -- Sandy Shores
    [7] = 1200000, -- Paleto Bay
    [8] = 150000, -- Strawberry
    [9] = 180000, -- Rancho
    [10] = 200000, -- Burton
    [11] = 900000, -- Vinewood Hills
    [12] = 300000, -- Chumash
    [13] = 250000, [14] = 250000, [15] = 250000, -- Ammunation
    [16] = 280000, [17] = 280000, [18] = 280000, -- Supermercados
    [19] = 240000, [20] = 240000, [21] = 240000, -- Postos
    [22] = 320000, [23] = 320000, [24] = 320000, -- Oficinas
    [25] = 150000, [26] = 150000, [27] = 150000, -- Bares
    [28] = 150000, [29] = 150000, [30] = 150000, -- Lojas de Roupas
    [31] = 500000, [32] = 500000, [33] = 500000, -- Bancos
    [34] = 850000, [35] = 600000, [36] = 500000, -- Aeroportos
    [37] = 120000, [38] = 120000, [39] = 120000, -- Barbearias
    [40] = 120000, [41] = 120000, [42] = 120000, -- Estúdios de Tatuagem
}

for i = 1, #config.hubs do
    local hub = config.hubs[i]
    hub.purchasePrice = priceMatrix[hub.id] or 250000
end

-- Modelos de Contratos em Lote da Empresa (Bulk Contracts)
config.companyContracts = {
    {
        id = 'restock_supermarket',
        title = 'Abastecer Supermercado Strawberry',
        description = 'Transportar 20 caixas de mantimentos do Porto de Los Santos ate Strawberry.',
        totalBoxes = 20,
        origin = vec3(154.0, -3212.0, 5.9),
        destination = vec3(25.7, -1347.3, 29.49),
        payout = 28000,
        xp = 450,
        mode = 'land'
    },
    {
        id = 'deliver_fuel_sandy',
        title = 'Entregar Combustivel em Sandy Shores',
        description = 'Transportar 35 caixas de combustivel do Porto ate Sandy Shores.',
        totalBoxes = 35,
        origin = vec3(154.0, -3212.0, 5.9),
        destination = vec3(2680.01, 3265.0, 55.24),
        payout = 42000,
        xp = 600,
        mode = 'land'
    },
    {
        id = 'weapons_transport_paleto',
        title = 'Transporte de Armamentos para Paleto',
        description = 'Transportar 15 caixas de municao pesada de Strawberry ate Paleto Bay.',
        totalBoxes = 15,
        origin = vec3(-43.0, -1748.0, 29.4),
        destination = vec3(-330.24, 6083.88, 31.45),
        payout = 32000,
        xp = 500,
        mode = 'land'
    }
}

-- Modelos e Precos de Funcionarios NPCs Disponiveis
config.npcTemplates = {
    { name = "Joao Silva", model = "s_m_m_dockwork_01", upfront = 5000, commission = 15 },
    { name = "Maria Santos", model = "s_f_y_scrubs_01", upfront = 8000, commission = 12 },
    { name = "Carlos Souza", model = "s_m_y_garbage", upfront = 4000, commission = 20 },
    { name = "Ana Oliveira", model = "s_f_m_shop_high", upfront = 10000, commission = 10 },
}

-- Popula os arrays planos para compatibilidade retroativa e rotas de entrega
for i = 1, #config.hubs do
    local hub = config.hubs[i]
    config.companyPurchase.points[i] = vec3(hub.coords.x, hub.coords.y, hub.coords.z)

    if hub.modes.land and hub.spawnCoords.land then
        local pt = vec3(hub.spawnCoords.land.x, hub.spawnCoords.land.y, hub.spawnCoords.land.z)
        config.freelance.points.land[#config.freelance.points.land + 1] = pt
        config.deliveryRoutes.land[#config.deliveryRoutes.land + 1] = pt
    end
    if hub.modes.water and hub.spawnCoords.water then
        config.freelance.points.water[#config.freelance.points.water + 1] = vec3(hub.spawnCoords.water.x, hub.spawnCoords.water.y, hub.spawnCoords.water.z)
    end
    if hub.modes.air and hub.spawnCoords.air then
        config.freelance.points.air[#config.freelance.points.air + 1] = vec3(hub.spawnCoords.air.x, hub.spawnCoords.air.y, hub.spawnCoords.air.z)
    end
end

return config
