fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_maintenance'
author 'Codex + Cidade Tycoon'
description 'Modulo de Manutencao, Desgaste e Oficinas da Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config/maintenance.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/wear_tear.lua',
    'server/items.lua',
    'server/ev_charging.lua',
    'server/body_damage.lua',
}

client_scripts {
    'client/main.lua',
    'client/wear_tear.lua',
    'client/wear_warnings.lua',
    'client/handling.lua',
    'client/items.lua',
    'client/ev_charging.lua',
    'client/body_damage.lua',
    'client/fix_visual.lua',
}

files {
    'config/maintenance.lua'
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
    'oxmysql',
    'cidade_tycoon_core'
}
