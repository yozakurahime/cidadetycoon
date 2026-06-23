local Config = {}

Config.Prices = {
    ['primaryColor'] = 500,
    ['secondaryColor'] = 300,
    ['pearlescentColor'] = 200,
    ['wheelColor'] = 150,
    ['wheels'] = 2000,
    ['windowTint'] = 400,
    ['neonToggle'] = 1000,
    ['neonColor'] = 500,
    ['xenonColor'] = 800,
    ['wash'] = 50,
    ['visualMod'] = 1200
}

Config.WheelCategories = {
    { id = 0, label = 'Sport' },
    { id = 1, label = 'Muscle' },
    { id = 2, label = 'Lowrider' },
    { id = 3, label = 'SUV' },
    { id = 4, label = 'Offroad' },
    { id = 5, label = 'Tuner' },
    { id = 6, label = 'Bike Wheels' },
    { id = 7, label = 'High End' },
    { id = 8, label = 'Bennys Original' },
    { id = 9, label = 'Bennys Custom' },
}

-- Proximity Settings
Config.WorkshopDistance = 15.0 -- Max distance from warehouse center

Config.Workshops = {
    vector3(1176.0, -3246.5, 7.0),
    vector3(1080.0, -2000.0, 31.0),
    vector3(-110.0, 6335.0, 31.5),
}

return Config
