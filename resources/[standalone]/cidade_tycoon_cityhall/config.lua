Config = {}

Config.Tax = {
    BaseAmount = 1500,
    PerVehicleAmount = 250,
    OverdueGraceDays = 3,    -- Days before suspension
    DailyFine = 500,         -- Fine per day of delay
    OfflineFreezeHours = 48, -- Stop accruing after 48h offline
    CheckDelayOnLogin = 30000 -- 30 seconds
}

Config.Locations = {
    ['cityhall_main'] = {
        type = 'npc',
        model = 's_m_m_office_01',
        coords = vec4(-544.9, -204.4, 38.2, 210.0), -- Inside Legion Sq City Hall
        label = 'Secretário da Prefeitura',
        icon = 'fa-solid fa-building-columns'
    },
    ['warehouse_kiosk_1'] = {
        type = 'prop',
        model = 'prop_terminal_01',
        coords = vec3(1205.2, -3105.8, 5.5), -- Near PostOP Hub
        label = 'Totem de Pagamentos',
        icon = 'fa-solid fa-credit-card'
    }
}

return Config
