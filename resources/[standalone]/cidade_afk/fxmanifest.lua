fx_version 'cerulean'
game 'gta5'

name 'cidade_afk'
author 'Cidade Tycoon'
description 'Sistema Anti-AFK - Dentro e fora do veiculo'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/config.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
}
