Config = {}

Config.MaxPurchasePerTurn = 5
Config.ProximityThreshold = 15.0 -- Server-side distance check

Config.Shelves = {
    ['mechanical'] = {
        title = 'Prateleira: Componentes Pesados',
        items = { 'engine_block', 'transmission_gear', 'suspension_arm' },
        icon = 'fa-solid fa-engine',
        label = 'Componentes Pesados',
        color = '~y~'
    },
    ['maintenance'] = {
        title = 'Prateleira: Itens de Manutenção',
        items = { 'basic_repair_kit', 'brake_pads', 'truck_tire' },
        icon = 'fa-solid fa-wrench',
        label = 'Itens de Manutencao',
        color = '~b~'
    }
}

Config.Recycling = {
    title = 'Estação de Reciclagem de Peças',
    icon = 'fa-solid fa-recycle',
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
