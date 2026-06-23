local Config = {}

Config.MaxPurchasePerTurn = 5
Config.ProximityThreshold = 15.0 -- Server-side distance check

-- Local do NPC Vendedor na Concessionária (PDM)
Config.NPC = {
    coords = vec4(-31.4220, -1114.0104, 26.4223, 74.0845), -- Coordenadas dentro da PDM
    model = "s_m_m_autoshop_01",
    scenario = "WORLD_HUMAN_CLIPBOARD",
    blip = {
        sprite = 402,
        color = 5,
        scale = 0.8,
        label = "Loja de Peças Tycoon"
    }
}

Config.ShopCategories = {
    {
        id = 'tires',
        title = 'Pneus & Aderência',
        icon = 'truck-fast',
        description = 'Kits de pneus para diversos terrenos e aplicações.',
        items = { 'standard_tires', 'truck_tire', 'tire_street_basic', 'tire_street_sport', 'tire_rain_pro', 'tire_offroad_pro', 'tire_drift_pro', 'tire_race_premium', 'drift_tires', 'racing_tires', 'drag_tires' }
    },
    {
        id = 'mechanical',
        title = 'Componentes Mecânicos',
        icon = 'gear',
        description = 'Blocos de motor, transmissões e suspensões.',
        items = { 'engine_block', 'transmission_gear', 'transmission_parts', 'transmission_street_kit', 'transmission_sport_kit', 'transmission_race_kit', 'suspension_arm', 'suspension_kit', 'suspension_sport_kit', 'clutch_performance' }
    },
    {
        id = 'consumables',
        title = 'Consumíveis & Reparos',
        icon = 'wrench',
        description = 'Freios, filtros, radiadores e kits de reparo rápido.',
        items = { 'basic_repair_kit', 'advanced_repair_kit', 'mechanical_parts', 'brake_pads', 'brake_street_basic', 'performance_brakes', 'brake_sport_kit', 'brake_race_kit', 'alignment_standard_service', 'filter_performance', 'radiator_heavy_duty' }
    },
    {
        id = 'premium',
        title = 'Peças de Performance',
        icon = 'gauge-high',
        description = 'Peças especiais: Turbos, ECUs e conversão de tração.',
        items = { 'ecu_sport_stage', 'turbo_street_kit', 'turbo_kit', 'supercharger_street_kit', 'drivetrain_conversion_fwd', 'drivetrain_conversion_rwd', 'drivetrain_conversion_awd', 'traction_control' }
    },
    {
        id = 'performance_kits',
        title = 'Kits de Performance',
        icon = 'gauge-high',
        description = 'Pacotes completos de comportamento para drag, drift e corrida.',
        items = { 'performance_kit_drag', 'performance_kit_drift', 'performance_kit_race' }
    },    {
        id = 'tools',
        title = 'Ferramentas & Equipamentos',
        icon = 'toolbox',
        description = 'Chaves, macacos hidráulicos e ferramentas avulsas (Preço de varejo).',
        items = { 'WEAPON_WRENCH', 'car_jack' }
    }
}

-- Lixeiras de Reciclagem mantidas nos Galpões
Config.WarehouseLocations = {
    vec3(1193.9, -3250.7, 7.1),
    vec3(1095.0, -2005.0, 31.0),
    vec3(-100.0, 6345.0, 31.5),
}

Config.Recycling = {
    title = 'Estação de Reciclagem de Peças',
    icon = 'recycle',
    label = 'Reciclagem de Sucata',
    color = '~g~',
    options = {
        {
            title = 'Reciclar Sucata Mecânica',
            item = 'mechanical_scrap',
            reward = 'raw_metal',
            amount = 5,
            icon = 'recycle'
        },
        {
            title = 'Reciclar Sucata Eletrônica',
            item = 'electronic_scrap',
            reward = 'raw_electronics',
            amount = 5,
            icon = 'microchip'
        }
    }
}

return Config
