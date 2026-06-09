Config = {}

-- ==========================================
-- FERRO-VELHO — Locais de Reciclagem
-- ==========================================
Config.Scrapyards = {
    {
        id = "la_puerta",
        label = "Ferro-Velho La Puerta",
        coords = vec4(-412.6, -1698.3, 19.0, 90.0),
        pedModel = "s_m_y_garbage",
        scenario = "WORLD_HUMAN_SMOKING",
        drops = {
            { item = "steel",   label = "Sucata de Aço",     weight = 40, minAmount = 2, maxAmount = 6 },
            { item = "plastic", label = "Plástico Reciclado", weight = 35, minAmount = 2, maxAmount = 5 },
            { item = "rubber",  label = "Borracha",           weight = 15, minAmount = 1, maxAmount = 3 },
            { item = "glass",   label = "Vidro Quebrado",     weight = 10, minAmount = 1, maxAmount = 4 },
        },
    },
    {
        id = "sandy_dump",
        label = "Lixão de Sandy Shores",
        coords = vec4(2400.5, 3130.2, 48.1, 180.0),
        pedModel = "s_m_y_garbage",
        scenario = "WORLD_HUMAN_BUM_WASH",
        drops = {
            { item = "rubber",  label = "Borracha",           weight = 35, minAmount = 2, maxAmount = 5 },
            { item = "plastic", label = "Plástico Reciclado", weight = 30, minAmount = 2, maxAmount = 5 },
            { item = "glass",   label = "Vidro Quebrado",     weight = 20, minAmount = 1, maxAmount = 4 },
            { item = "steel",   label = "Sucata de Aço",      weight = 15, minAmount = 1, maxAmount = 3 },
        },
    },
    {
        id = "paleto_wreck",
        label = "Desmanche Paleto Bay",
        coords = vec4(-455.2, 6101.6, 31.4, 135.0),
        pedModel = "s_m_y_construct_01",
        scenario = "WORLD_HUMAN_HAMMERING",
        drops = {
            { item = "steel",   label = "Sucata de Aço",     weight = 50, minAmount = 3, maxAmount = 7 },
            { item = "plastic", label = "Plástico Reciclado", weight = 20, minAmount = 1, maxAmount = 4 },
            { item = "rubber",  label = "Borracha",           weight = 15, minAmount = 1, maxAmount = 3 },
            { item = "glass",   label = "Vidro Quebrado",     weight = 15, minAmount = 1, maxAmount = 3 },
        },
    },
    {
        id = "el_burro",
        label = "Depósito El Burro Heights",
        coords = vec4(916.3, -1688.5, 31.0, 0.0),
        pedModel = "s_m_y_dockwork_01",
        scenario = "WORLD_HUMAN_CLIPBOARD",
        drops = {
            { item = "plastic", label = "Plástico Reciclado", weight = 35, minAmount = 2, maxAmount = 6 },
            { item = "rubber",  label = "Borracha",           weight = 30, minAmount = 2, maxAmount = 5 },
            { item = "glass",   label = "Vidro Quebrado",     weight = 20, minAmount = 2, maxAmount = 5 },
            { item = "steel",   label = "Sucata de Aço",      weight = 15, minAmount = 1, maxAmount = 3 },
        },
    },
}

-- ==========================================
-- LABORATÓRIOS CLANDESTINOS — Químicos Ilegais
-- Alta recompensa, alto risco
-- ==========================================
Config.Labs = {
    {
        id = "desert_lab",
        label = "Laboratório Abandonado do Deserto",
        coords = vec4(349.0, 3514.8, 35.4, 0.0),
        pedModel = "s_m_y_dealer_01",
        scenario = "WORLD_HUMAN_DRUG_DEALER",
        drops = {
            { item = "raw_chemicals", label = "Produtos Químicos", weight = 100, minAmount = 3, maxAmount = 7 },
        },
    },
    {
        id = "warehouse_lab",
        label = "Galpão Clandestino La Mesa",
        coords = vec4(924.0, -1334.2, 25.8, 180.0),
        pedModel = "s_m_y_dealer_01",
        scenario = "WORLD_HUMAN_DRUG_DEALER",
        drops = {
            { item = "raw_chemicals", label = "Produtos Químicos", weight = 100, minAmount = 3, maxAmount = 6 },
        },
    },
    {
        id = "docks_lab",
        label = "Contêiner Suspeito — Elysian Island",
        coords = vec4(1258.7, -3188.5, 5.9, 90.0),
        pedModel = "s_m_y_dealer_01",
        scenario = "WORLD_HUMAN_DRUG_DEALER",
        drops = {
            { item = "raw_chemicals", label = "Produtos Químicos", weight = 100, minAmount = 4, maxAmount = 8 },
        },
    },
}

-- Risco Policial (chance de alertar polícia ao coletar)
Config.PoliceAlertChance = 0.15  -- 15%
Config.PoliceAlertMessage = "Um laboratório clandestino foi detectado nas proximidades."

-- ==========================================
-- CONFIGURAÇÃO GERAL DE COLETA
-- ==========================================
Config.ProgressBarDuration = 10000  -- 10 segundos
Config.SkillCheckDifficulty = { 'easy', 'medium', 'medium' }
Config.SkillCheckKeys = { 'w', 'a', 's', 'd' }
Config.ExperiencePerScavenge = 10
Config.ExperiencePerLab = 20

-- Cooldown por local (ms)
Config.ScrapCooldown = 30000   -- 30 segundos ferro-velho
Config.LabCooldown = 60000     -- 60 segundos laboratório

-- Tooltip quando cooldown ativo
Config.CooldownMessage = "Os materiais ainda não se renovaram. Aguarde..."
