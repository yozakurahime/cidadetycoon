fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_compat'
author 'Codex + Cidade Tycoon'
description 'Camada temporaria de compatibilidade para a modularizacao do Cidade Tycoon'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/contracts.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'cidade_tycoon_core',
}
