fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_racing'
author 'Codex + Cidade Tycoon'
description 'Modulo de Corridas, Rankings e Competições da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/events.lua',
    'server/seed.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/events.lua',
}

dependencies {
    'ox_lib',
    'cidade_tycoon_core',
}
