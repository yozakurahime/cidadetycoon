fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_production'
description 'Tycoon industrial production system with instances'
author 'Cidade Tycoon'
lua54 'yes'

shared_scripts {
    'config/shared.lua'
}

client_scripts {
    '@ox_lib/init.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@ox_lib/init.lua',
    'server/main.lua'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'qbx_core',
    'cidade_tycoon_core'
}
