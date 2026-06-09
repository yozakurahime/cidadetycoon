fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_scrapyard'
description 'Ferro-velho e laboratório clandestino — reciclagem e coleta química'
author 'Cidade Tycoon'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'qbx_core',
    'cidade_tycoon_core'
}
