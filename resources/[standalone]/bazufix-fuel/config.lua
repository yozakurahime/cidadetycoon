--[[

         ____                  ______ _      
        |  _ \                |  ____(_)     
        | |_) | __ _ _____   _| |__   ___  __
        |  _ < / _` |_  / | | |  __| | \ \/ /
        | |_) | (_| |/ /| |_| | |    | |>  < 
        |____/ \__,_/___|\__,_|_|    |_/_/\_\                                                                           
                                                        
    BAZUFIX FUEL V2.5 | Advanced System | by Bazu Store

        FRAMEWORK: 'esx' | 'qb' | 'qbox' | 'auto'
    'auto' → automatically detects the framework, recommended.
]]--

Config = {}

-- ─────────────────────────────────────────────
--  FRAMEWORK
-- ─────────────────────────────────────────────
Config.Framework = 'qb'   -- 'esx' | 'qb' | 'qbox' | 'auto'

Config.RunAutoSQL = true    -- true: automatically runs the SQL file | false: manual SQL installation required

-- ─────────────────────────────────────────────
--  LANGUAGE SETTINGS
--  Supported Locales: 
--  'tr' - Turkish
--  'en' - English
--  'fr' - French
--  'es' - Spanish
--  'de' - German
--  'ar' - Arabic
--  'ru' - Russian
--  'nl' - Dutch
--  'zh' - Chinese
--  'he' - Hebrew
--  'ja' - Japanese
--  'el' - Greek
--  'bg' - Bulgarian

-- ─────────────────────────────────────────────
Config.Locale = 'pt-br'  -- Choose from the list above

-- ─────────────────────────────────────────────
--  GENERAL SETTINGS
-- ─────────────────────────────────────────────
Config.Settings = {
    FuelDecor        = 'bzfuel_level',       -- Decorator name (do not change)
    DefaultFuelMin    = 30,                   -- Min fuel % when spawning/entering vehicle
    DefaultFuelMax    = 80,                   -- Max fuel % when spawning/entering vehicle
    LowFuelThreshold  = 15,                   -- Low fuel warning threshold (%)
    EngineOffAtZero   = true,                 -- Should the engine turn off when fuel is empty?
    RefuelSpeed       = 500,                  -- Refueling speed (ms per litre)
    PumpInteractDist  = 2.0,                  -- Interaction distance for pumps
    NozzleModel       = 'prop_cs_fuel_nozle',
    ShowHUD           = false,                -- Show fuel HUD while in vehicle
    HUDPosition       = 'bottom-right',       -- 'bottom-right' | 'bottom-left'
    TaxRate           = 0.85,                 -- Income share for station owner (0.85 = 85%)
    ServerCut         = 0.10,                 -- Server treasury share (0.10 = 10%)
    BuyInteractDist   = 3.0,                  -- Interaction distance to buy stations
    DefaultStockFuel  = 5000,                 -- Initial stock for newly purchased stations (litres)
    MaxStockFuel      = 50000,                -- Maximum stock capacity (litres)
    StockWarnLevel    = 500,                  -- Stock warning level (litres)
    StockPricePerL    = 5,                    -- Wholesale fuel cost for station owner ($/litre)
}

-- Font IDs: 0 = Standard, 1 = Cursive, 2 = Monospace, 4 = Chalet London (Default)
Config.TextFont = 4

-- ─────────────────────────────────────────────
--  INTERACTION KEYS (GTA V control codes)
-- ─────────────────────────────────────────────
Config.Keys = {
    Interact  = 38,  -- E
    Return    = 47,  -- G
}

-- ─────────────────────────────────────────────
--  FUEL CONSUMPTION (RPM x Class multiplier)
-- ─────────────────────────────────────────────
Config.FuelUsage = {
    [0.0] = 0.0,
    [0.1] = 0.10,
    [0.2] = 0.20,
    [0.3] = 0.30,
    [0.4] = 0.15,
    [0.5] = 0.25,
    [0.6] = 0.35,
    [0.7] = 0.40,
    [0.8] = 0.45,
    [0.9] = 0.50,
    [1.0] = 0.55,
}

Config.Classes = {
    [0]  = 0.90,   -- Compacts
    [1]  = 0.95,   -- Sedans
    [2]  = 1.10,   -- SUVs
    [3]  = 0.95,   -- Coupes
    [4]  = 1.10,   -- Muscle
    [5]  = 1.20,   -- Sports Classics
    [6]  = 1.25,   -- Sports
    [7]  = 1.40,   -- Super
    [8]  = 0.75,   -- Motorcycles
    [9]  = 1.15,   -- Off-road
    [10] = 1.30,   -- Industrial
    [11] = 1.20,   -- Utility
    [12] = 1.05,   -- Vans
    [13] = 0.00,   -- Cycles (no fuel)
    [14] = 1.00,   -- Boats
    [15] = 2.00,   -- Helicopters
    [16] = 2.50,   -- Planes
    [17] = 1.00,   -- Service
    [18] = 1.10,   -- Emergency
    [19] = 1.50,   -- Military
    [20] = 1.40,   -- Commercial
    [21] = 0.00,   -- Trains (no fuel)
}

-- Vehicle classes that do not consume fuel
Config.FuelFalseClass = {
    [13] = true,  -- Cycles
    [21] = true,  -- Trains
}

-- Blacklisted vehicle models (no fuel consumption)
Config.FuelBlacklistModels = {
    `hydra`,
    `lazer`,
    `b11`,
    `nokota`,
    `besra`,
    `militjet`,
}

-- Electric vehicle models
Config.ElectricVehicles = {
    'neon', 'voltic', 'tezeract', 'cyclone', 'raiden',
    'surge', 'dilettante', 'khamelion', 'imorgon',
    'iwagen', 'everon', 'futurism',
}

-- ─────────────────────────────────────────────
--  ADMIN CONTROL
--  Admin control is handled by bazufix-core.
--  --> exports['bazufix-core']:IsPlayerAuthorized(src, 'bazufix-fuel')
-- ─────────────────────────────────────────────

-- ─────────────────────────────────────────────
--  ADMIN COMMANDS
-- ─────────────────────────────────────────────
Config.Commands = {
    Stations = 'fueladmin',  -- Command to open admin station panel
    SetFuel  = 'setfuel',    -- Command to set a player's fuel level
}

-- ─────────────────────────────────────────────
--  FUEL PRICES (Default - can be changed by stations owner)
-- ─────────────────────────────────────────────
Config.DefaultPrices = {
    economic = 9,
    normal   = 13,
    super    = 19,
    electric = 7,
}

-- ─────────────────────────────────────────────
--  MAX FUEL PRICES (Hard ceiling for all stations)
--  Station owners cannot set prices above these values.
--  Server-side clamp is also applied as a security layer.
-- ─────────────────────────────────────────────
Config.MaxPrices = {
    economic = 22,
    normal   = 34,
    super    = 55,
    electric = 18,
}

-- ─────────────────────────────────────────────
--  PUMP MODELS
-- ─────────────────────────────────────────────
Config.FuelPumpModels = {
    -2007231801,
    1339433404,
    1694452750,
    1933174915,
    -462817101,
    -469694731,
    -164877493,
}

-- ─────────────────────────────────────────────
--  STATIONS
--  coords      : General location (for blip)
--  buyLocation : Purchase point (Press E to buy)
--  zone        : Active refueling zone
--  blip        : Map icon settings
--  fuel_price  = { economic = 10, normal = 15, super = 22, electric = 8 },  -- Custom prices or 'default' default = Config.DefaultPrices

-- ─────────────────────────────────────────────

Config.BuyStations = true -- Set to false to disable all station purchases; individual stations can be toggled via 'buyable' in Config.Stations.

Config.Stations = {
    [1] = {
        name        = 'GSD 68 Gas Station',
        buyable     = true,
        buyPrice    = 150000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(49.4187, 2778.793, 58.043),
        buyLocation = vector3(46.21, 2788.78, 57.88),
        zone        = { coords = vector3(49.4187, 2778.793, 58.043), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [2] = {
        name        = 'GSD 4023 Gas Station',
        buyable     = true,
        buyPrice    = 120000,
        fuel_price  = { economic = 10, normal = 15, super = 22, electric = 8 },  -- Custom prices
        coords      = vector3(1039.958, 2671.134, 39.550),
        buyLocation = vector3(1039.25, 2664.22, 39.55),
        zone        = { coords = vector3(1039.958, 2671.134, 39.550), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [3] = {
        name        = 'GSD 4025 Gas Station',
        buyable     = true,
        buyPrice    = 130000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(1207.260, 2660.175, 37.899),
        buyLocation = vector3(1203.12, 2655.97, 37.85),
        zone        = { coords = vector3(1207.260, 2660.175, 37.899), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [4] = {
        name        = 'Senora Way Gas Station',
        buyable     = true,
        buyPrice    = 140000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(2539.685, 2594.192, 37.944),
        buyLocation = vector3(2542.000, 2591.500, 37.944),
        zone        = { coords = vector3(2539.685, 2594.192, 37.944), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [5] = {
        name        = 'Strawberry Gas Station',
        buyable     = true,
        buyPrice    = 200000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(265.648, -1261.309, 29.292),
        buyLocation = vector3(288.13, -1266.66, 29.44),
        zone        = { coords = vector3(265.648, -1261.309, 29.292), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [6] = {
        name        = 'La Mesa Gas Station',
        buyable     = true,
        buyPrice    = 220000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(819.653, -1028.846, 26.403),
        buyLocation = vector3(818.15, -1039.49, 26.75),
        zone        = { coords = vector3(819.653, -1028.846, 26.403), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [7] = {
        name        = 'MirrorPark Gas Station',
        buyable     = true,
        buyPrice    = 350000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(1181.381, -330.847, 69.316),
        buyLocation = vector3(1159.94, -316.33, 69.21),
        zone        = { coords = vector3(1181.381, -330.847, 69.316), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [8] = {
        name        = 'Davis Gas Station',
        buyable     = true,
        buyPrice    = 110000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(-70.2148, -1761.792, 29.534),
        buyLocation = vector3(-45.52, -1750.72, 29.42),
        zone        = { coords = vector3(-70.2148, -1761.792, 29.534), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [9] = {
        name        = 'Little Seoul Gas Station',
        buyable     = true,
        buyPrice    = 180000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(-526.019, -1211.003, 18.184),
        buyLocation = vector3(-531.1, -1220.52, 18.45),
        zone        = { coords = vector3(-526.019, -1211.003, 18.184), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [10] = {
        name        = 'Lindsay Circus Gas Station',
        buyable     = true,
        buyPrice    = 190000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(-724.619, -935.1631, 19.213),
        buyLocation = vector3(-709.25, -906.98, 19.22),
        zone        = { coords = vector3(-724.619, -935.1631, 19.213), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [11] = {
        name        = 'Downtown Vinewood Gas Station',
        buyable     = true,
        buyPrice    = 250000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(620.72, 268.86, 103.09),
        buyLocation = vector3(644.87, 267.9, 103.2),
        zone        = { coords = vector3(620.72, 268.86, 103.09), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [12] = {
        name        = 'Paleto Bay Gas Station',
        buyable     = true,
        buyPrice    = 170000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(179.75, 6602.73, 31.87),
        buyLocation = vector3(169.27, 6625.92, 31.75),
        zone        = { coords = vector3(179.75, 6602.73, 31.87), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [13] = {
        name        = 'Sandy Shores Gas Station',
        buyable     = true,
        buyPrice    = 150000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(2004.99, 3775.09, 32.4),
        buyLocation = vector3(2001.68, 3779.22, 32.18),
        zone        = { coords = vector3(2004.99, 3775.09, 32.4), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
    [14] = {
        name        = 'Lago Zancudo Gas Station',
        buyable     = true,
        buyPrice    = 160000,
        fuel_price  = 'default',   -- Uses Config.DefaultPrices
        coords      = vector3(-2555.35, 2334.6, 33.08),
        buyLocation = vector3(-2556.92, 2317.02, 33.22),
        zone        = { coords = vector3(-2555.35, 2334.6, 33.08), size = vector3(25, 25, 10) },
        blip        = { sprite = 361, color = 1, scale = 0.7 },
    },
}
