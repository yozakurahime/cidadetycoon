fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_maintenance'
author 'Cidade Tycoon'
description 'Modulo de manutencao, desgaste e faturamento de veiculos da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/wear_tear.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
    'client/wear_tear.lua',
}

files {
    'config/maintenance.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'cidade_tycoon_core',
}
