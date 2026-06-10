fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_tablet'
author 'Codex + Cidade Tycoon'
description 'Modulo de Tablet Operacional da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js',
    'ui/icons/*',
    'ui/js/**/*.js',
    'ui/wallpapers/*',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql',
    'cidade_tycoon_core',
    'cidade_tycoon_logistics',
    'cidade_tycoon_freelance'
}
