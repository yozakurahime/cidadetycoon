fx_version 'cerulean'
game 'gta5'

name 'cidade_tycoon_trucklogistics'
description 'Cidade Tycoon truck logistics company gameplay'
author 'Cidade Tycoon'
lua54 'yes'

ui_page 'nui/ui.html'

shared_scripts {
	'@ox_lib/init.lua',
}

client_scripts {
	'lang/br.lua',
	'lang/en.lua',
	'config.lua',
	'utils.lua',
	'client.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'lang/br.lua',
	'lang/en.lua',
	'config.lua',
	'server/init.lua',
	'server.lua',
}

files {
	'nui/ui.html',
	'nui/panel.js',
	'nui/style.css',
	'nui/img/avatar1.png',
	'nui/img/avatar2.png',
	'nui/img/avatar3.png',
	'nui/img/avatar4.png',
	'nui/img/avatar5.png',
	'nui/img/avatar6.png',
	'nui/img/avatar7.png',
	'nui/img/avatar8.png',
	'nui/img/bg_template.png',
	'nui/img/daf.jpg',
	'nui/img/hauler.jpg',
	'nui/img/packer.jpg',
	'nui/img/phantom.jpg',
	'nui/img/truck.png',
	'nui/img/phantom3.png',
	'nui/img/mule5.png',
	'nui/img/pounder2.png',
	'nui/img/benson.png',
	'nui/img/stockade.png',
	'nui/img/barracks3.png',
}

dependencies {
	'oxmysql',
	'qbx_core',
	'ox_target',
	'cidade_tycoon_core',
}
