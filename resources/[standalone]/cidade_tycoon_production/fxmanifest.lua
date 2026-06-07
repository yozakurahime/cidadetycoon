fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_production'
author 'Cidade Tycoon'
description 'Modulo de Produção Industrial e Processamento de Cargas da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'cidade_tycoon_core',
    'cidade_tycoon_logistics',
}
