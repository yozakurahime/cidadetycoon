Config = {}

-- ==========================================
-- MINAS — Locais de Mineração
-- Cada mina tem seu tipo de minério predominante
-- ==========================================

Config.Mines = {
    -- Pedreira Davis Quartz (Sul de Los Santos)
    {
        id = "davis_quartz",
        label = "Pedreira Davis Quartz",
        coords = vec4(2998.5, 2767.2, 43.3, 180.0),
        pedModel = "s_m_y_construct_01",
        scenario = "WORLD_HUMAN_SMOKING",
        -- Distribuição de drops (pesos relativos)
        drops = {
            { item = "iron_ore",   label = "Minério de Ferro",  weight = 45, minAmount = 3, maxAmount = 7 },
            { item = "aluminum",   label = "Alumínio Bruto",    weight = 30, minAmount = 2, maxAmount = 5 },
            { item = "copper_wire", label = "Fio de Cobre",     weight = 15, minAmount = 1, maxAmount = 4 },
            { item = "stone",      label = "Pedra Bruta",       weight = 10, minAmount = 2, maxAmount = 6 },
        },
    },
    -- Mina do Monte Chilliad (Túnel)
    {
        id = "chilliad_mine",
        label = "Mina do Monte Chilliad",
        coords = vec4(496.5, 5573.0, 793.2, 270.0),
        pedModel = "s_m_y_construct_02",
        scenario = "WORLD_HUMAN_CLIPBOARD",
        drops = {
            { item = "iron_ore",    label = "Minério de Ferro",  weight = 55, minAmount = 4, maxAmount = 8 },
            { item = "aluminum",    label = "Alumínio Bruto",    weight = 25, minAmount = 2, maxAmount = 5 },
            { item = "copper_wire", label = "Fio de Cobre",      weight = 15, minAmount = 2, maxAmount = 4 },
            { item = "stone",       label = "Pedra Bruta",       weight = 5,  minAmount = 1, maxAmount = 3 },
        },
    },
    -- Mina Great Chaparral (Deserto)
    {
        id = "great_chaparral",
        label = "Mina de Great Chaparral",
        coords = vec4(-589.2, 2091.3, 131.0, 90.0),
        pedModel = "s_m_y_construct_01",
        scenario = "WORLD_HUMAN_HAMMERING",
        drops = {
            { item = "iron_ore",    label = "Minério de Ferro",  weight = 35, minAmount = 3, maxAmount = 6 },
            { item = "copper_wire", label = "Fio de Cobre",      weight = 35, minAmount = 3, maxAmount = 6 },
            { item = "aluminum",    label = "Alumínio Bruto",    weight = 20, minAmount = 2, maxAmount = 4 },
            { item = "stone",       label = "Pedra Bruta",       weight = 10, minAmount = 2, maxAmount = 5 },
        },
    },
    -- Pedreira Harmony
    {
        id = "harmony_quarry",
        label = "Pedreira Harmony",
        coords = vec4(2956.2, 2785.4, 42.4, 0.0),
        pedModel = "s_m_y_construct_02",
        scenario = "WORLD_HUMAN_CLIPBOARD",
        drops = {
            { item = "iron_ore",    label = "Minério de Ferro",  weight = 40, minAmount = 3, maxAmount = 7 },
            { item = "aluminum",    label = "Alumínio Bruto",    weight = 25, minAmount = 2, maxAmount = 5 },
            { item = "copper_wire", label = "Fio de Cobre",      weight = 20, minAmount = 2, maxAmount = 5 },
            { item = "stone",       label = "Pedra Bruta",       weight = 15, minAmount = 2, maxAmount = 6 },
        },
    },
}

-- Configuração do Minigame
Config.ProgressBarDuration = 12000  -- 12 segundos de mineração
Config.SkillCheckDifficulty = { 'medium', 'medium', 'hard' }
Config.SkillCheckKeys = { 'w', 'a', 's', 'd' }

-- XP concedido ao minerar com sucesso
Config.ExperiencePerMine = 15

-- Cooldown por mina (ms) para evitar spam
Config.MineCooldown = 45000  -- 45 segundos

-- Item necessário para minerar (se nil, qualquer um pode)
Config.RequiredItem = nil -- "pickaxe" -- descomente quando o item for registrado

-- Chance de falha catastrófica (perde a picareta)
Config.PickaxeBreakChance = 0.05 -- 5%
