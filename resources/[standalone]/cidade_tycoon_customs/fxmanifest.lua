fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_customs'
author 'Codex + Cidade Tycoon'
description 'Modulo de Customização Estética e Identidade Visual de Frota da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

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

dependencies {
    'ox_lib',
    'cidade_tycoon_core',
}
