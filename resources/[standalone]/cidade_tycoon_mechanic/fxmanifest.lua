fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_mechanic'
author 'Codex + Cidade Tycoon'
description 'Sistema de Mecânicos da Cidade Tycoon (Diagnóstico e Reparos)'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/tools.lua',
    'server/shops.lua',
}

client_scripts {
    'client/main.lua',
    'client/tools.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
    'ox_inventory',
    'oxmysql',
    'cidade_tycoon_core',
    'cidade_tycoon_maintenance'
}
