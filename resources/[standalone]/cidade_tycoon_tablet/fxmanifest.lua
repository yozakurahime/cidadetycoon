fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_tablet'
author 'Codex + Cidade Tycoon'
description 'Gateway do jogador e NUI do tablet da Cidade Tycoon'
version '1.0.0'

lua54 'yes'
use_experimental_fxv2_oal 'yes'
ui_page 'ui/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
}

files {
    'config/shared.lua',
    'ui/index.html',
    'ui/style.css',
    'ui/app.js',
    'ui/icons/*',
    'ui/vehicle_images.json',
    'ui/images/vehicles/*',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql',
    'cidade_tycoon_core',
    'cidade_tycoon_freelance',
}
