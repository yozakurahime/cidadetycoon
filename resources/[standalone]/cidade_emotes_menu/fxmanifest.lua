fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cidade_emotes_menu'
author 'Cidade Tycoon'
description 'Unified Qbox emote menu with local player preview'
version '1.0.0'

dependency 'cidade_emotes'

shared_scripts {
    '@ox_lib/init.lua',
    '@cidade_emotes/config.lua',
    '@cidade_emotes/Translations.lua',
    '@cidade_emotes/animals.lua'
}

client_scripts {
    '@cidade_emotes/client/AnimationList.lua',
    '@cidade_emotes/client/AnimationListCustom.lua',
    '@cidade_emotes/client/AnimationListDeado.lua',
    '@cidade_emotes/client/AnimationListDeadoBridge.lua',
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
