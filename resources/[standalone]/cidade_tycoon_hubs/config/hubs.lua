TycoonHubs = {}

TycoonHubs.Config = {
    hubs = {
        {
            id = 1,
            name = "Porto de Los Santos - Transportes",
            coords = vec4(1196.5, -3250.8, 7.1, 90.0), -- Interior PostOP
            pedModel = "s_m_m_trucker_01",
            scenario = "WORLD_HUMAN_CLIPBOARD",
            title = "Despachante Portuário",
            modes = { land = true, water = true },
            spawnCoords = {
                land = vec4(1185.0, -3235.0, 6.0, 180.0),
                water = vec4(1298.0, -3167.0, 0.0, 180.0),
            },
            productionCoords = vec3(1202.0, -3258.0, 7.1),
            purchasePrice = 350000
        },
        {
            id = 2,
            name = "La Mesa - Logistica",
            coords = vec4(716.8, -962.1, 24.9, 180.0), -- Interior Armazém
            pedModel = "s_m_m_dockwork_01",
            scenario = "WORLD_HUMAN_CLIPBOARD",
            title = "Gerente de Operações",
            modes = { land = true },
            spawnCoords = {
                land = vec4(724.0, -973.0, 24.9, 270.0),
            },
            productionCoords = vec3(712.0, -958.0, 24.9),
            purchasePrice = 220000
        },
        {
            id = 3,
            name = "Elysian Island - Marina & Cargas",
            coords = vec4(153.9, -3211.7, 5.9, 270.0),
            pedModel = "s_m_m_dockwork_01",
            scenario = "WORLD_HUMAN_STAND_MOBILE",
            title = "Encarregado de Docas",
            modes = { land = true, water = true },
            spawnCoords = {
                land = vec4(164.0, -3220.0, 5.9, 90.0),
                water = vec4(255.0, -3004.0, 5.8, 180.0),
            },
            productionCoords = vec3(150.0, -3215.0, 5.9),
            purchasePrice = 350000
        },
        {
            id = 4,
            name = "Terminal - Armazem Central",
            coords = vec4(1200.0, -1275.0, 35.2, 90.0),
            pedModel = "s_m_m_trucker_01",
            scenario = "WORLD_HUMAN_CLIPBOARD",
            title = "Controlador de Tráfego",
            modes = { land = true },
            spawnCoords = {
                land = vec4(1218.0, -1269.0, 35.2, 180.0),
            },
            productionCoords = vec3(1195.0, -1270.0, 35.2),
            purchasePrice = 420000
        },
        {
            id = 5,
            name = "Grapeseed - Armazem Norte",
            coords = vec4(1694.5, 4896.2, 42.1, 0.0), -- Shed Interior
            pedModel = "s_m_m_trucker_01",
            scenario = "WORLD_HUMAN_CLIPBOARD",
            title = "Logística Rural",
            modes = { land = true, air = true },
            spawnCoords = {
                land = vec4(1694.0, 4908.0, 42.1, 0.0),
                air = vec4(1690.0, 4935.0, 42.1, 90.0),
            },
            productionCoords = vec3(1705.0, 4902.0, 42.1),
            purchasePrice = 500000
        },
        {
            id = 6,
            name = "Sandy Shores - Aerodromo & Cargas",
            coords = vec4(1960.0, 3745.0, 32.3, 130.0),
            pedModel = "s_m_y_garbage",
            scenario = "WORLD_HUMAN_STAND_MOBILE",
            title = "Fiscal de Pista",
            modes = { land = true, air = true },
            spawnCoords = {
                land = vec4(1943.0, 3754.0, 32.2, 220.0),
                air = vec4(1955.0, 3720.0, 32.2, 130.0),
            },
            productionCoords = vec3(1965.0, 3750.0, 32.3),
            purchasePrice = 600000
        },
        {
            id = 7,
            name = "Paleto Bay - Logistica Global",
            coords = vec4(2678.0, 3288.0, 55.2, 45.0),
            pedModel = "s_m_m_trucker_01",
            scenario = "WORLD_HUMAN_CLIPBOARD",
            title = "Diretor Regional",
            modes = { land = true, water = true, air = true },
            spawnCoords = {
                land = vec4(2686.0, 3265.0, 55.2, 135.0),
                water = vec4(-1596.43, 5262.64, 3.97, 180.0),
                air = vec4(2690.0, 3300.0, 55.2, 90.0),
            },
            productionCoords = vec3(2670.0, 3295.0, 55.2),
            purchasePrice = 1200000
        },
    },

    shops = {
        {
            id = "dealership_main",
            type = "market",
            name = "Concessionaria Central LS",
            coords = vec4(-33.8, -1102.2, 26.4, 160.0),
            pedModel = "s_m_y_autoula_01",
            scenario = "WORLD_HUMAN_STAND_MOBILE",
            title = "Consultor de Vendas",
            blip = { sprite = 326, color = 3 }
        },
        {
            id = "autoparts_main",
            type = "autoparts",
            name = "Loja de Peças Tycoon",
            coords = vec4(1184.6, -3113.6, 6.0, 180.0), -- NPC fixo no Porto
            pedModel = "s_m_y_dockwork_01",
            scenario = "WORLD_HUMAN_STAND_MOBILE",
            title = "Vendedor de Peças",
            blip = { sprite = 402, color = 5 }
        },
        {
            id = "cityhall_main",
            type = "cityhall",
            name = "Prefeitura de Los Santos",
            coords = vec4(-545.0, -204.0, 38.2, 210.0),
            pedModel = "s_f_m_shop_high",
            scenario = "WORLD_HUMAN_STAND_MOBILE",
            title = "Secretária do Gabinete",
            blip = { sprite = 419, color = 0 }
        },
        {
            id = "mechanic_central",
            type = "workshop",
            name = "Oficina Central Tycoon",
            coords = vec4(-337.0, -135.0, 39.0, 70.0),
            pedModel = "s_m_y_mechanic_01",
            scenario = "WORLD_HUMAN_WELDING",
            title = "Mecânico Chefe",
            blip = { sprite = 446, color = 5 }
        },
        {
            id = "mechanic_paleto",
            type = "workshop",
            name = "Oficina Paleto Bay",
            coords = vec4(110.0, 6620.0, 32.0, 270.0),
            pedModel = "s_m_y_mechanic_01",
            scenario = "WORLD_HUMAN_MAINTENANCE",
            title = "Mecânico de Paleto",
            blip = { sprite = 446, color = 5 }
        }
    }
}

return TycoonHubs.Config
