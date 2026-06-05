fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cidade_tycoon_worldbuilder'
author 'Cidade Tycoon'
description 'Editor persistente de props e remocoes de mapa para hubs e lojas.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependency 'ox_lib'
