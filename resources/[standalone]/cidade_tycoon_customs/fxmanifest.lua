fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_customs'
author 'Codex + Cidade Tycoon'
description 'Modulo de Customizacao Estetica e Identidade Visual de Frota da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

ui_page 'ui/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config/shared.lua',
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
    'ui/index.html',
    'ui/style.css',
    'ui/app.js',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'oxmysql',
    'okokBanking',
    'cidade_tycoon_core',
}
