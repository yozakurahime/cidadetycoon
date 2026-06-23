fx_version 'adamant'
game 'gta5'
author 'okok#3488'
description 'okokBanking'
ui_page 'web/ui.html'
files {
    'web/*.*'
}
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}
client_scripts {
    'client.lua'
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
