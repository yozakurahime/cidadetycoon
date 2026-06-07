fx_version 'cerulean'
game 'gta5'

name 'cidade_chat'
author 'Cidade Tycoon'
description 'Sistema de chat imersivo e reativo alinhado com a HUD da cidade.'
version '1.0.0'

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
    'nui/fonts/*.woff2'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

provide 'chat'

lua54 'yes'
