fx_version 'cerulean'
game 'gta5'

author 'Antigravity'
description 'Filmmaker Suite for Cidade Tycoon'
version '1.0.0'

shared_script '@ox_lib/init.lua'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
    'nui/clack.mp3'
}

dependencies {
    'ox_lib',
    'ox_target'
}
