fx_version 'cerulean'
game 'gta5'

name 'cidade_garagem_eye'
description 'Garagem custom da Cidade Tycoon com terceiro olho'
version '1.0.0'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
    'client/garage_admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/garage_manager.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
    'qbx_garages',
}
