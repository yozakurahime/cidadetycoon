fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_racing'
author 'Codex + Cidade Tycoon'
description 'Modulo de Corridas, Rankings e Competições da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/events.lua',
}

client_scripts {
    'client/events.lua',
}

dependencies {
    'ox_lib',
    'cidade_tycoon_core',
}
