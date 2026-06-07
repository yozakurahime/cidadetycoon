fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_hubs'
author 'Codex + Cidade Tycoon'
description 'Modulo de Sedes Logisticas (Hubs) da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config/hubs.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
}
