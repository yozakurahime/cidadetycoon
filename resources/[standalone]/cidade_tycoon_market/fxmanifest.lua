fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_market'
author 'Codex + Cidade Tycoon'
description 'Modulo de aquisição de veiculos, financiamento e mercado da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/financing.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'cidade_tycoon_core',
}
