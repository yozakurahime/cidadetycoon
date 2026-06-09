fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_mining'
description 'Mineração de matérias-primas para a Cidade Tycoon'
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
