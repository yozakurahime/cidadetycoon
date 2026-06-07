fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_logistics'
author 'Codex + Cidade Tycoon'
description 'Modulo de Logística Avançada, Gestão de Empresas e Frota NPC'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config/shared.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
    'server/fleet.lua',
    'server/npc_manager.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'cidade_tycoon_core',
}
