fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_maintenance'
author 'Codex + Cidade Tycoon'
description 'Modulo de Manutenção, Desgaste e Oficinas da Cidade Tycoon'
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
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql',
    'cidade_tycoon_core'
}
