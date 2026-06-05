fx_version "cerulean"
game "gta5"

author "Cidade Tycoon"
description "Cinematic Studio - live camera editor for film capture"

ui_page "html/index.html"

files {
	"html/index.html",
	"html/style.css",
	"html/app.js"
}

client_scripts {
	"replay.lua",
	"client.lua"
}

server_script "server.lua"
