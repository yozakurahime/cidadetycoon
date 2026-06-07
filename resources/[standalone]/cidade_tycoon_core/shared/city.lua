TycoonCore = TycoonCore or {}

TycoonCore.City = {
    cityHall = {
        enabled = true,
        pedModel = 's_m_m_fiboffice_01',
        coords = vec4(-545.41, -204.08, 38.22, 210.0),
        interactionDistance = 2.5,
    },

    personalDealership = {
        enabled = true,
        pedModel = 's_m_m_autoshop_02',
        coords = vec4(-47.91, -1096.78, 26.42, 160.0),
        interactionDistance = 2.5,
    },

    companyDealership = {
        enabled = true,
        pedModel = 's_m_m_trucker_01',
        coords = vec4(1202.0, -1274.0, 35.22, 90.0),
        interactionDistance = 2.5,
    },

    autoParts = {
        enabled = true,
        pedModel = 's_m_m_dockwork_01',
        coords = vec4(1184.58, -3113.62, 6.03, 180.0),
        interactionDistance = 2.2,
        blip = {
            sprite = 402,
            color = 5,
            scale = 0.8,
            label = 'Auto Peças Tycoon'
        }
    },
}

return TycoonCore.City
