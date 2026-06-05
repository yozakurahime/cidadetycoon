
fx_version 'adamant'
game 'gta5'

author 'c8re'
description 'Core Inventory - Advaced grid based inventory'
fx_version 'adamant'
game 'gta5'

author 'c8re'
description 'Most advanced inventory on FiveM (Tarkov based)'
version '1.3.0'

ui_page 'html/form.html'

files {
	'html/form.html',
	'html/css.css',
	'html/gradient.png',
	'html/script.js',
	'html/jquery-3.4.1.min.js',
	'html/img/*.png',
	'html/*.svg',
	'sounds/*.mp3',
	'stream/*.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'core_bbox.ytyp'

shared_scripts {
    "@ox_lib/init.lua",
    -- "@es_extended/imports.lua", -- Removed for Qbox conversion
    'config.lua'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'oxmysql'
}

client_scripts{
    'config.lua',
    'client/main.lua',
}

server_scripts{
    "@oxmysql/lib/MySQL.lua",
    'config.lua',
    'server/bridge.lua',
    'server/main2.lua',
    'server/metadata.lua',
    'server/server.lua'
}

lua54 'yes'
