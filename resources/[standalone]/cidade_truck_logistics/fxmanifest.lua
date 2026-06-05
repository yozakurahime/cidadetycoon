fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Cidade Tycoon'
description 'Truck logistics adapted for Qbox/Cidade Tycoon'

ui_page "nui/ui.html"

client_scripts {
	"lang/br.lua",
	"lang/en.lua",	
	"config.lua",
	"utils.lua",
	"client.lua",
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	"lang/br.lua",
	"lang/en.lua",
	"config.lua",
	"server/init.lua",
	"server.lua",
}

files {
	"nui/ui.html",
	"nui/panel.js",
	"nui/style.css",
	"nui/img/*"
}

dependencies {
	'oxmysql',
	'qbx_core',
	'qbx_vehiclekeys'
}
