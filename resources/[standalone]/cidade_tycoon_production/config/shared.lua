Config = {}

-- ==========================================
-- GERAL
-- ==========================================
Config.Entrance = {
    coords = vec4(155.7565, -3203.2197, 6.0219, 274.3145), -- Ao lado do porto
    pedModel = "s_m_y_dockwork_01",
    scenario = "WORLD_HUMAN_CLIPBOARD"
}

Config.Freelance = {
    coords = vec4(1197.2, -3250.6, 7.1, 90.0), -- PostOP Docks entrance original
    pedModel = "s_m_m_trucker_01",
    scenario = "WORLD_HUMAN_CLIPBOARD",
    name = "Porto de Los Santos - Freelance"
}

Config.Interior = {
    -- Criminal Enterprise Warehouse (Instanciado via Routing Buckets)
    coords = vec4(849.1, -3000.2, -45.97, 0.0),
    exitCoords = vec4(849.1, -3000.2, -45.97, 0.0), -- Ponto de saída interno
}

-- ==========================================
-- PREÇOS E PROGRESSÃO
-- ==========================================
Config.CreationPrice = 500000 -- R$ 500.000 para abrir a primeira empresa
Config.MaxMembersPerLevel = {
    [1] = 3,
    [5] = 5,
    [10] = 8,
    [20] = 12
}

Config.ExperiencePerAction = 25 -- EXP ganha por cada mini-game de produção concluído

Config.Levels = {
    [1] = { exp = 0, label = "Oficina de Fundo de Quintal" },
    [2] = { exp = 1000, label = "Micro-Indústria" },
    [3] = { exp = 2500, label = "Pequena Fábrica" },
    [5] = { exp = 6000, label = "Centro Industrial" },
    [10] = { exp = 15000, label = "Conglomerado de Manufatura" },
}

-- ==========================================
-- PRODUTOS (Exemplos Iniciais)
-- ==========================================
Config.Products = {
    -- LEGAIS
    ["steel_plate"] = {
        label = "Chapa de Aço",
        type = "legal",
        minLevel = 1,
        requirements = { { item = "iron_ore", count = 10 } },
        processTime = 15000, -- 15 segundos
    },
    ["mechanical_parts"] = {
        label = "Peças Mecânicas",
        type = "legal",
        minLevel = 3,
        requirements = { { item = "iron_ore", count = 5 }, { item = "aluminum", count = 5 } },
        processTime = 25000,
    },
    -- ILEGAIS (Desbloqueiam no Nível 10)
    ["refined_powder"] = {
        label = "Pó Refinado",
        type = "illegal",
        minLevel = 10,
        requirements = { { item = "raw_chemicals", count = 5 } },
        processTime = 40000,
    },
    ["blueprint_weapon"] = {
        label = "Projeto de Armamento",
        type = "illegal",
        minLevel = 10,
        requirements = { { item = "steel_plate", count = 20 }, { item = "mechanical_parts", count = 10 } },
        processTime = 60000,
    }
}

-- ==========================================
-- MAQUINÁRIO / SLOTS FÍSICOS NO GALPÃO (Offsets do CE Warehouse)
-- ==========================================
Config.MachineSlots = {
    -- SETOR LEGAL (Bancadas de ferramentas) - Parede Esquerda
    { model = "prop_tool_bench02", type = "legal", minLevel = 1, coords = vec4(842.0, -3005.0, -45.97, 90.0) },
    { model = "prop_tool_bench02", type = "legal", minLevel = 1, coords = vec4(842.0, -3010.0, -45.97, 90.0) },
    { model = "prop_tool_bench02", type = "legal", minLevel = 3, coords = vec4(842.0, -3015.0, -45.97, 90.0) },
    { model = "prop_tool_bench02", type = "legal", minLevel = 5, coords = vec4(845.0, -3018.0, -45.97, 180.0) },
    { model = "prop_tool_bench02", type = "legal", minLevel = 5, coords = vec4(848.0, -3018.0, -45.97, 180.0) },
    
    -- SETOR ILEGAL (Mesas de laboratório) - Parede Direita
    { model = "bkr_prop_meth_table01a", type = "illegal", minLevel = 10, coords = vec4(856.0, -3005.0, -45.97, 270.0) },
    { model = "bkr_prop_meth_table01a", type = "illegal", minLevel = 10, coords = vec4(856.0, -3010.0, -45.97, 270.0) },
    { model = "bkr_prop_meth_table01a", type = "illegal", minLevel = 10, coords = vec4(856.0, -3015.0, -45.97, 270.0) },
}
