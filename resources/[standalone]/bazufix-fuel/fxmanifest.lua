fx_version 'cerulean'
game 'gta5'

author 'BazuFix'
description 'BazuFix Fuel System v2.5.3 - Advanced Fuel & Station Management'
version '2.5.3'
lua54 'yes'

ui_page 'ui/ui.html'

files {
    'ui/ui.html',
    'ui/ui.css',
    'ui/ui.js',
    'ui/assets/*.png',
    'ui/assets/*.webp',
    'ui/assets/*.svg'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/*.lua'
}

client_scripts {
    'client/main.lua',
    'client/fuel.lua',
    'client/station.lua',
    'client/hud.lua',
    'client/ui.lua',
    'client/buy.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/station.lua',
    'server/economy.lua',
}

dependencies {
    'ox_lib',
    'oxmysql'
}

escrow_ignore {
    'config.lua',
    'locales/*.lua'
}

dependency '/assetpacks'