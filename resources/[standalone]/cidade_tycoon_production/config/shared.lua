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
    [1]  = 3,
    [5]  = 5,
    [10] = 8,
    [15] = 10,
    [20] = 12,
    [25] = 15,
    [30] = 18,
    [40] = 22,
}

Config.ExperiencePerAction = 25 -- EXP ganha por cada mini-game de produção concluído

Config.Levels = {
    [1]  = { exp = 0,      label = "Oficina de Fundo de Quintal" },
    [2]  = { exp = 1000,   label = "Micro-Indústria" },
    [3]  = { exp = 2500,   label = "Pequena Fábrica" },
    [5]  = { exp = 6000,   label = "Centro Industrial" },
    [7]  = { exp = 10000,  label = "Planta de Produção" },
    [10] = { exp = 15000,  label = "Conglomerado de Manufatura" },
    [13] = { exp = 25000,  label = "Complexo Industrial" },
    [15] = { exp = 35000,  label = "Polo Tecnológico" },
    [18] = { exp = 55000,  label = "Corporação de Engenharia" },
    [20] = { exp = 75000,  label = "Indústria de Ponta" },
    [22] = { exp = 100000, label = "Laboratório Avançado" },
    [25] = { exp = 130000, label = "Megaindústria Tycoon" },
    [30] = { exp = 200000, label = "Império de Manufatura" },
    [35] = { exp = 300000, label = "Lenda Industrial" },
    [40] = { exp = 500000, label = "Titã da Produção" },
    [45] = { exp = 800000, label = "Magnata da Indústria" },
}

-- ==========================================
-- PRODUTOS FABRICÁVEIS
-- ==========================================
Config.Products = {
    -- ─── LEGAIS (Setor Esquerdo: tool_bench02 / tool_bench03) ───
    ["steel_plate"] = {
        label = "Chapa de Aço",
        type = "legal",
        minLevel = 1,
        requirements = { { item = "iron_ore", count = 10 } },
        processTime = 15000,
    },
    ["mechanical_parts"] = {
        label = "Peças Mecânicas",
        type = "legal",
        minLevel = 3,
        requirements = { { item = "iron_ore", count = 5 }, { item = "aluminum", count = 5 } },
        processTime = 25000,
    },
    ["electronic_circuit"] = {
        label = "Circuito Eletrônico",
        type = "legal",
        minLevel = 5,
        requirements = { { item = "copper_wire", count = 8 }, { item = "plastic", count = 5 }, { item = "aluminum", count = 3 } },
        processTime = 30000,
    },
    ["reinforced_frame"] = {
        label = "Chassi Reforçado",
        type = "legal",
        minLevel = 7,
        requirements = { { item = "steel_plate", count = 8 }, { item = "mechanical_parts", count = 4 } },
        processTime = 35000,
    },
    ["engine_block"] = {
        label = "Bloco de Motor",
        type = "legal",
        minLevel = 10,
        requirements = { { item = "steel_plate", count = 15 }, { item = "mechanical_parts", count = 10 }, { item = "aluminum", count = 5 } },
        processTime = 50000,
    },

    -- ─── ILEGAIS (Setor Direito: meth_table01a / heist_cut_table) ───
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
    },
    ["counterfeit_chip"] = {
        label = "Chip Falsificado",
        type = "illegal",
        minLevel = 13,
        requirements = { { item = "electronic_circuit", count = 5 }, { item = "plastic", count = 10 }, { item = "raw_chemicals", count = 3 } },
        processTime = 45000,
    },
    ["explosive_compound"] = {
        label = "Composto Explosivo",
        type = "illegal",
        minLevel = 15,
        requirements = { { item = "raw_chemicals", count = 12 }, { item = "refined_powder", count = 3 } },
        processTime = 55000,
    },
    ["military_grade_weapon"] = {
        label = "Armamento de Grau Militar",
        type = "illegal",
        minLevel = 17,
        requirements = { { item = "blueprint_weapon", count = 3 }, { item = "steel_plate", count = 25 }, { item = "explosive_compound", count = 2 } },
        processTime = 90000,
    },

    -- ─── ESPECIAIS (Fundo + Ilha Central: prop_bench_01a / v_serv_tray01 / tool_bench03) ───
    ["turbo_kit"] = {
        label = "Kit Turbo Artesanal",
        type = "special",
        minLevel = 8,
        requirements = { { item = "mechanical_parts", count = 10 }, { item = "steel_plate", count = 5 }, { item = "electronic_circuit", count = 3 } },
        processTime = 45000,
    },
    ["drone_module"] = {
        label = "Módulo de Drone",
        type = "special",
        minLevel = 15,
        requirements = { { item = "electronic_circuit", count = 8 }, { item = "aluminum", count = 5 }, { item = "plastic", count = 5 } },
        processTime = 50000,
    },
    ["experimental_alloy"] = {
        label = "Liga Experimental",
        type = "special",
        minLevel = 18,
        requirements = { { item = "steel_plate", count = 20 }, { item = "aluminum", count = 10 }, { item = "copper_wire", count = 5 } },
        processTime = 65000,
    },
    ["quantum_processor"] = {
        label = "Processador Quântico",
        type = "special",
        minLevel = 20,
        requirements = { { item = "electronic_circuit", count = 15 }, { item = "counterfeit_chip", count = 5 }, { item = "experimental_alloy", count = 3 } },
        processTime = 120000,
    },
    ["prototype_weapon"] = {
        label = "Arma Protótipo",
        type = "special",
        minLevel = 25,
        requirements = { { item = "military_grade_weapon", count = 2 }, { item = "quantum_processor", count = 1 }, { item = "experimental_alloy", count = 5 } },
        processTime = 180000,
    },
}

-- ==========================================
-- MAQUINÁRIO / SLOTS FÍSICOS NO GALPÃO (CE Warehouse Interior)
-- Galpão: X=838~862, Y=-2990~-3025, Z=-45.97
-- Pilares: X≈846.5, X≈852.5  |  Y≈-3002, Y≈-3014
-- ==========================================
Config.MachineSlots = {
    -- ╔══════════════════════════════════════════════════════════════╗
    -- ║ PAREDE ESQUERDA — SETOR LEGAL (Bancadas de Ferramentas)    ║
    -- ║ X=841.5, heading=90° (voltadas para o centro do galpão)    ║
    -- ║ 12 slots — nível 1 a 16 — passo Y=2.5m                     ║
    -- ╚══════════════════════════════════════════════════════════════╝
    { model = "prop_tool_bench02",  type = "legal", minLevel = 1,  coords = vec4(841.5, -2994.0, -45.97, 90.0) },
    { model = "prop_tool_bench02",  type = "legal", minLevel = 1,  coords = vec4(841.5, -2996.5, -45.97, 90.0) },
    { model = "prop_tool_bench02",  type = "legal", minLevel = 1,  coords = vec4(841.5, -2999.0, -45.97, 90.0) },
    { model = "prop_tool_bench02",  type = "legal", minLevel = 3,  coords = vec4(841.5, -3001.5, -45.97, 90.0) },
    { model = "prop_tool_bench02",  type = "legal", minLevel = 3,  coords = vec4(841.5, -3004.0, -45.97, 90.0) },
    { model = "prop_tool_bench02",  type = "legal", minLevel = 5,  coords = vec4(841.5, -3006.5, -45.97, 90.0) },
    { model = "prop_tool_bench02",  type = "legal", minLevel = 5,  coords = vec4(841.5, -3009.0, -45.97, 90.0) },
    { model = "prop_tool_bench02",  type = "legal", minLevel = 7,  coords = vec4(841.5, -3011.5, -45.97, 90.0) },
    { model = "prop_tool_bench03",  type = "legal", minLevel = 7,  coords = vec4(841.5, -3014.0, -45.97, 90.0) },
    { model = "prop_tool_bench03",  type = "legal", minLevel = 10, coords = vec4(841.5, -3016.5, -45.97, 90.0) },
    { model = "prop_tool_bench03",  type = "legal", minLevel = 13, coords = vec4(841.5, -3019.0, -45.97, 90.0) },
    { model = "prop_tool_bench03",  type = "legal", minLevel = 16, coords = vec4(841.5, -3021.5, -45.97, 90.0) },

    -- ╔══════════════════════════════════════════════════════════════╗
    -- ║ PAREDE DIREITA — SETOR ILEGAL (Mesas de Laboratório)       ║
    -- ║ X=857.5, heading=270° (voltadas para o centro do galpão)   ║
    -- ║ 8 slots — nível 10 a 20 — passo Y=2.5m                     ║
    -- ╚══════════════════════════════════════════════════════════════╝
    { model = "bkr_prop_meth_table01a",     type = "illegal", minLevel = 10, coords = vec4(857.5, -2995.0, -45.97, 270.0) },
    { model = "bkr_prop_meth_table01a",     type = "illegal", minLevel = 10, coords = vec4(857.5, -2997.5, -45.97, 270.0) },
    { model = "bkr_prop_meth_table01a",     type = "illegal", minLevel = 10, coords = vec4(857.5, -3000.0, -45.97, 270.0) },
    { model = "bkr_prop_meth_table01a",     type = "illegal", minLevel = 12, coords = vec4(857.5, -3002.5, -45.97, 270.0) },
    { model = "hei_prop_heist_cut_table_01", type = "illegal", minLevel = 13, coords = vec4(857.5, -3005.0, -45.97, 270.0) },
    { model = "hei_prop_heist_cut_table_01", type = "illegal", minLevel = 15, coords = vec4(857.5, -3007.5, -45.97, 270.0) },
    { model = "hei_prop_heist_cut_table_01", type = "illegal", minLevel = 17, coords = vec4(857.5, -3010.0, -45.97, 270.0) },
    { model = "hei_prop_heist_cut_table_01", type = "illegal", minLevel = 20, coords = vec4(857.5, -3012.5, -45.97, 270.0) },

    -- ╔══════════════════════════════════════════════════════════════╗
    -- ║ PAREDE DO FUNDO — SETOR AVANÇADO (Montagem & Acabamento)   ║
    -- ║ Y=-3024.0, heading=0° (voltadas para o corredor central)   ║
    -- ║ 5 slots — nível 8 a 22 — passo X=3.0m                      ║
    -- ╚══════════════════════════════════════════════════════════════╝
    { model = "prop_bench_01a",  type = "legal",   minLevel = 8,  coords = vec4(843.0, -3024.0, -45.97, 0.0) },
    { model = "prop_bench_01a",  type = "legal",   minLevel = 10, coords = vec4(846.0, -3024.0, -45.97, 0.0) },
    { model = "v_serv_tray01",   type = "illegal", minLevel = 15, coords = vec4(849.0, -3024.0, -45.97, 0.0) },
    { model = "v_serv_tray01",   type = "special", minLevel = 18, coords = vec4(852.0, -3024.0, -45.97, 0.0) },
    { model = "v_serv_tray01",   type = "special", minLevel = 22, coords = vec4(855.0, -3024.0, -45.97, 0.0) },

    -- ╔══════════════════════════════════════════════════════════════╗
    -- ║ ILHA CENTRAL — SETOR EXPERIMENTAL (freestanding no galpão) ║
    -- ║ Y=-3008.5 (meio do galpão), heading=180° (voltadas p/ sul) ║
    -- ║ 2 slots — nível 20 e 25 — passo X=4.0m                     ║
    -- ╚══════════════════════════════════════════════════════════════╝
    { model = "prop_tool_bench03",  type = "special", minLevel = 20, coords = vec4(849.0, -3008.5, -45.97, 180.0) },
    { model = "prop_tool_bench03",  type = "special", minLevel = 25, coords = vec4(853.0, -3008.5, -45.97, 180.0) },

    -- ╔══════════════════════════════════════════════════════════════╗
    -- ║ FUTURAS EXPANSÕES (comentadas — prontas para ativar)       ║
    -- ║ Mais 4 slots na ilha central para níveis 30-45             ║
    -- ╚══════════════════════════════════════════════════════════════╝
    -- { model = "v_serv_tray01",      type = "special", minLevel = 30, coords = vec4(849.5, -3012.0, -45.97, 0.0) },
    -- { model = "v_serv_tray01",      type = "special", minLevel = 35, coords = vec4(853.5, -3012.0, -45.97, 0.0) },
    -- { model = "prop_bench_01a",     type = "special", minLevel = 40, coords = vec4(849.5, -3005.0, -45.97, 0.0) },
    -- { model = "prop_tool_bench03",  type = "special", minLevel = 45, coords = vec4(853.5, -3005.0, -45.97, 0.0) },
}
