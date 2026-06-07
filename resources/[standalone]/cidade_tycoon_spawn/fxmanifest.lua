fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_spawn'
author 'Codex + Cidade Tycoon'
description 'Cinematic Spawn System with Private Character Creation'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'qbx_core',
    'ox_lib',
}
