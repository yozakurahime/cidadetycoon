fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_core'
author 'Codex + Cidade Tycoon'
description 'Core minimo compartilhado para os modulos do Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/constants.lua',
    'shared/logger.lua',
    'shared/plates.lua',
    'shared/city.lua',
    'shared/config.lua',
    'shared/upgrades.lua',
    'shared/vehicles.lua',
    'shared/parts.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/profile.lua',
    'server/skills.lua',
    'server/vehicles.lua',
    'server/civic.lua',
    'server/transactions.lua',
    'server/vehicle_status.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'oxmysql',
}
