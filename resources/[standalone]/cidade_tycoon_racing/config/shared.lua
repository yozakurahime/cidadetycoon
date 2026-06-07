Config = {}

Config.Events = {
    minInterval = 20 * 60 * 1000, -- 20 mins
    maxInterval = 50 * 60 * 1000, -- 50 mins
    payoutTiers = { 1.0, 0.35, 0.15 }, -- 1st, 2nd, 3rd place multiplier
    allowedClasses = { 10, 11, 12, 20 }, -- Vans, Trucks, Service, Commercial
    passiveRadius = 100.0,
    checkpoints = {
        { label = 'Porto de Los Santos', coords = vec3(1214.8, -1262.3, 35.2) },
        { label = 'Terminal de Cargas LS', coords = vec3(-716.4, -915.5, 19.2) },
        { label = 'Pedreira Davis Quartz', coords = vec3(2681.8, 3290.4, 55.2) },
        { label = 'Sede Rural (Farm)', coords = vec3(1702.9, 4920.6, 42.0) },
        { label = 'Cypress Flats Ind.', coords = vec3(-42.0, -1749.2, 29.4) },
    }
}

Config.Gambling = {
    minBet = 1000,
    maxBetWithoutOwner = 10000,
    escrowFee = 0.05 -- 5% fee for corporate duels
}

return Config
