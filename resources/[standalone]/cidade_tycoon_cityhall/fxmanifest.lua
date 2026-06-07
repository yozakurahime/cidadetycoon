fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_cityhall'
author 'Codex + Cidade Tycoon'
description 'Modulo de Prefeitura, Licenças e Sistema Fiscal da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'cidade_tycoon_core',
}
