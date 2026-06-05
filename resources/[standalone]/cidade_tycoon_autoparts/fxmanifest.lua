fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_autoparts'
author 'Codex + Cidade Tycoon'
description 'Modulo de Loja de Peças e Mercado de Reposição da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'cidade_tycoon_core',
}
