TycoonHubs = {}

TycoonHubs.Config = {
    hubs = {
        {
            id = 1,
            name = "Porto de Los Santos - PostOP",
            coords = vec4(1197.2, -3250.6, 7.1, 90.0), -- PostOP Docks
            pedModel = "s_m_m_trucker_01",
            scenario = "WORLD_HUMAN_CLIPBOARD",
            title = "Despachante Portuário",
            modes = { land = true, water = true, air = true },
            spawnCoords = {
                land = vec4(1185.0, -3235.0, 6.0, 180.0),
                water = vec4(1298.0, -3167.0, 0.0, 180.0),
                air = vec4(1170.0, -3235.0, 6.0, 180.0), -- Approximate spawn for air if used later
            },
            productionCoords = vec4(1193.9069, -3250.7424, 7.0952, 271.6763),
            autopartsCoords = vec3(1176.0, -3246.5, 7.0),
            purchasePrice = 350000
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
