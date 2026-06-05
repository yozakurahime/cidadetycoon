fx_version 'cerulean'
game 'gta5'

ui_page "nui/index.html"

client_scripts {
	"config/config.lua",
	"client.lua"
}

server_scripts {
	"config/config.lua",
	"server.lua"
}

files {
	"nui/*.html",
	"nui/*.js",
	"nui/*.css",
	"nui/bibs/loading-bar.css",
	"nui/bibs/loading-bar.js",
	"nui/svgs/*.svg",
	"nui/svgs/*.png",
}

dependencies {
	'qbx_core',
}
