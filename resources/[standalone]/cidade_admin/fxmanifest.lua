fx_version 'cerulean'
game 'gta5'

name 'cidade_admin'
author 'Cidade Tycoon'
description 'Painel Administrativo da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/commands.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/admin_menu.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'cidade_tycoon_core',
}
