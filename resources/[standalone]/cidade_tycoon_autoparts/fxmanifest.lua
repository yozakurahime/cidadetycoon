fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_autoparts'
author 'Codex + Cidade Tycoon'
description 'Modulo de Loja de Peças e Mercado de Reposição da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'cidade_tycoon_core'
}
