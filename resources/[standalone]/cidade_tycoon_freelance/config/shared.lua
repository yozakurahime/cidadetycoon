local config = {}

config.freelance = {
    deliveryRadius = 15.0,
    serverValidationDistance = 25.0,
    pickupOriginDistance = 5.0,
    unloadVehicleDistance = 5.0,

    baseRewardPerBox = {
        land = 1750,
        water = 2200,
        air = 3500,
    },

    rewardMultipliers = {
        comum = 1.0,
        fragile = 1.4,
        heavy = 1.8,
        hazardous = 2.5,
    },

    points = {
        land = {
            vector3(441.1, -981.4, 30.7),   -- DP LSPD (Misc Cargo)
            vector3(-631.2, -236.7, 38.1),  -- Jewelry Vangelico (Valuable)
            vector3(1196.7, -3253.5, 7.1),  -- B docks
            vector3(2750.5, 3474.3, 55.4),  -- Paleto Farm
            vector3(1697.7, 4924.5, 42.1),  -- Grapeseed
            vector3(-3038.5, 584.2, 7.9),   -- Ocean motion
            vector3(1174.6, 2640.4, 37.8),  -- Sandy Mech
            vector3(-1154.5, -1520.1, 4.4), -- Vic´s
            vector3(-181.5, 6223.1, 31.5),  -- Paleto Gas
        },
        air = {
            vector3(-1037.1, -2737.5, 20.2), -- LSIA
            vector3(1741.5, 3269.4, 41.1),   -- Sandy Airport
            vector3(-2183.1, 3144.3, 32.8),  -- Military Base
            vector3(2132.8, 4779.1, 41.1),   -- McKenzie
        },
        water = {
            vector3(-804.8, -1505.7, 1.6),  -- Del Perro Pier
            vector3(1313.1, -3075.2, 0.5),  -- South Docks
            vector3(3133.3, 4458.1, 1.7),   -- Catfish View
            vector3(-3424.3, 963.5, 1.6),   -- Chumash
        }
    }
}

config.hubs = {
    [1] = {
        name = "Porto de Los Santos - Logística Global",
        coords = vector3(1197.2, -3250.6, 7.1),
        modes = { land = true, water = true, air = true },
    },
}

return config
