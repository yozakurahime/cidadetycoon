local Config = {}

Config.WholesaleDiscount = 0.5 -- 50% discount for mechanics
Config.ProximityThreshold = 15.0

Config.Suppliers = {
    {
        coords = vec4(118.8, -3030.0, 6.0, 90.0), -- Example: LSC
        model = "s_m_y_xmech_01",
        scenario = "WORLD_HUMAN_CLIPBOARD"
    },
    {
        coords = vec4(733.9, -1085.3, 22.16, 180.0), -- Example: Mirror Park Auto
        model = "s_m_y_xmech_02",
        scenario = "WORLD_HUMAN_CLIPBOARD"
    }
}

Config.WholesaleCategories = {
    {
        id = 'tools',
        title = 'Ferramentas Oficiais',
        icon = 'toolbox',
        items = { 'WEAPON_WRENCH', 'car_jack' }
    },
    {
        id = 'repair',
        title = 'Kits e Pecas de Reparo',
        icon = 'wrench',
        items = { 'basic_repair_kit', 'advanced_repair_kit', 'mechanical_parts' }
    },
    {
        id = 'engine',
        title = 'Motor / Performance',
        icon = 'gauge-high',
        items = { 'engine_block', 'filter_performance', 'radiator_heavy_duty', 'ecu_sport_stage', 'turbo_street_kit', 'turbo_kit', 'supercharger_street_kit' }
    },
    {
        id = 'transmission',
        title = 'Transmissao',
        icon = 'gears',
        items = { 'transmission_gear', 'transmission_parts', 'clutch_performance', 'transmission_street_kit', 'transmission_sport_kit', 'transmission_race_kit' }
    },
    {
        id = 'drivetrain',
        title = 'Tracao / Controle',
        icon = 'route',
        items = { 'drivetrain_conversion_fwd', 'drivetrain_conversion_rwd', 'drivetrain_conversion_awd', 'traction_control' }
    },
    {
        id = 'brakes',
        title = 'Freios',
        icon = 'circle-stop',
        items = { 'brake_pads', 'brake_street_basic', 'performance_brakes', 'brake_sport_kit', 'brake_race_kit' }
    },
    {
        id = 'suspension',
        title = 'Suspensao / Alinhamento',
        icon = 'car-burst',
        items = { 'suspension_arm', 'suspension_kit', 'suspension_sport_kit', 'alignment_standard_service' }
    },
    {
        id = 'tires',
        title = 'Pneus',
        icon = 'truck-fast',
        items = { 'standard_tires', 'truck_tire', 'tire_street_basic', 'tire_street_sport', 'tire_rain_pro', 'tire_offroad_pro', 'tire_drift_pro', 'tire_race_premium', 'drift_tires', 'racing_tires', 'drag_tires' }
    },
    {
        id = 'performance_kits',
        title = 'Kits de Performance',
        icon = 'gauge-high',
        items = { 'performance_kit_drag', 'performance_kit_drift', 'performance_kit_race' }
    },    {
        id = 'electric',
        title = 'Eletricos',
        icon = 'bolt',
        items = { 'battery' }
    }
}

return Config
