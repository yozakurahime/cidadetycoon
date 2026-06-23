-- shared/config.lua
-- Admin system configuration

local Config = {}

-- Permission levels
Config.Permissions = {
    ['god'] = 100,
    ['admin'] = 80,
    ['mod'] = 50,
    ['support'] = 30,
}

-- Commands and minimum permission level required
Config.Commands = {
    -- Player Management
    kick = 'mod',
    warn = 'mod',
    freeze = 'mod',
    unfreeze = 'mod',
    bring = 'mod',
    ['goto'] = 'mod',
    setjob = 'admin',
    setgang = 'admin',

    -- Vehicle
    car = 'mod',
    dv = 'mod',
    repair = 'mod',
    fix = 'mod',

    -- Economy
    giveMoney = 'admin',
    giveItem = 'admin',
    setLevel = 'admin',

    -- Server
    weather = 'admin',
    time = 'admin',
    restart = 'god',
    announcement = 'admin',

    -- Tycoon
    tycoonSetLevel = 'admin',
    tycoonGiveXP = 'admin',
    tycoonSetRep = 'admin',
    tycoonReset = 'god',
    tycoonSetSkill = 'admin',
}

-- Specific identifiers with god/admin access (beyond ACE groups)
-- Format: identifier:value
Config.SpecialIdentifiers = {
    -- Discord IDs with god access
    ['discord:157240838668156928'] = 'god', -- himezinha
}

-- Menu Categories
Config.MenuCategories = {
    {
        id = 'players',
        title = 'Jogadores',
        icon = 'users',
        color = '#5ac8fa',
    },
    {
        id = 'vehicles',
        title = 'Veiculos',
        icon = 'car',
        color = '#34c759',
    },
    {
        id = 'economy',
        title = 'Economia',
        icon = 'dollar-sign',
        color = '#ff9f0a',
    },
    {
        id = 'server',
        title = 'Servidor',
        icon = 'server',
        color = '#bf5af2',
    },
    {
        id = 'tycoon',
        title = 'Tycoon',
        icon = 'building',
        color = '#ff6482',
    },
    {
        id = 'tools',
        title = 'Ferramentas',
        icon = 'screwdriver-wrench',
        color = '#8e8e93',
    },
}

return Config
