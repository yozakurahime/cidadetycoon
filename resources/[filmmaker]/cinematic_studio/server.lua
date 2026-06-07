local exportSerial = 0

local function notify(source, kind, message)
    local notifyType = ({ sucesso = "success", negado = "error", aviso = "warning", importante = "inform" })[kind] or "inform"
    if GetResourceState("qbx_core") == "started" then
        exports.qbx_core:Notify(source, message, notifyType)
    else
        TriggerClientEvent("ox_lib:notify", source, { title = "Cinematic Studio", description = message, type = notifyType })
    end
end
local function hasStudioPermission(source)
	if source == 0 then return true end
	
	-- Qbox group checks
	if GetResourceState("qbx_core") == "started" then
		return IsPlayerAceAllowed(source, "filmmaker.tools")
			or exports.qbx_core:HasGroup(source, "admin")
			or exports.qbx_core:HasGroup(source, "god")
			or exports.qbx_core:HasGroup(source, "filmmaker")
	-- QBCore fallback
	elseif GetResourceState("qb-core") == "started" then
		local QBCore = exports['qb-core']:GetCoreObject()
		return QBCore.Functions.HasPermission(source, "admin") or QBCore.Functions.HasPermission(source, "god")
	else
		-- Standalone/Ace permission fallback
		return IsPlayerAceAllowed(source, "command") or IsPlayerAceAllowed(source, "filmmaker.tools")
	end
end

RegisterCommand("studio",function(source)
	if source > 0 and hasStudioPermission(source) then
		TriggerClientEvent("cinematic_studio:toggle",source)
	end
end)

RegisterCommand("take",function(source,args)
	if source <= 0 or not hasStudioPermission(source) then return end

	local action = string.lower(args[1] or "")
	if action == "start" or action == "stop" or action == "clear" then
		TriggerClientEvent("cinematic_studio:takeAction",source,action)
	else
		notify(source,"aviso","Use: /take start, /take stop ou /take clear")
	end
end)

RegisterNetEvent("cinematic_studio:exportFrame")
AddEventHandler("cinematic_studio:exportFrame",function()
	local source = source
	if source <= 0 or not hasStudioPermission(source) then return end

	exportSerial = (exportSerial + 1) % 1000
	local fileName = ("resources/%s/exports/user_%s_%s_%03d.png"):format(
		GetCurrentResourceName(),
		tostring(source),
		os.date("%Y%m%d_%H%M%S"),
		exportSerial
	)

	exports["screenshot-basic"]:requestClientScreenshot(source,{
		fileName = fileName,
		encoding = "png",
		quality = 1.0
	},function(error)
		if error then
			notify(source,"negado","Falha ao exportar o frame PNG.")
		else
			notify(source,"sucesso","Frame PNG exportado na pasta cinematic_studio/exports.")
		end
	end)
end)

local animationPresets = {
	acenar = true,
	celular = true,
	prancheta = true,
	dancar = true,
	sentar = true,
	parar = true
}

local fxPresets = {
	explosao = true,
	fogo = true,
	fumaca = true,
	flash = true
}

local ptfxPresets = {
	faisca = true,
	fumaca = true,
	fogo = true,
	poeira = true
}

local soundPresets = {
	corte = true,
	impacto = true,
	missao = true,
	entrada = true
}

local function validNativeName(value)
	return type(value) == "string" and #value > 0 and #value <= 80 and value:match("^[%w_@%-%^/]+$") ~= nil
end

RegisterCommand("cineanim",function(source,args)
	if source <= 0 or not hasStudioPermission(source) then return end
	local preset = string.lower(args[1] or "")
	if not animationPresets[preset] then
		notify(source,"aviso","Use: /cineanim acenar|celular|prancheta|dancar|sentar|parar")
		return
	end
	TriggerClientEvent("cinematic_studio:sceneEvent",-1,{
		kind = "anim",
		actor = tostring(source),
		preset = preset ~= "parar" and preset or nil,
		action = preset == "parar" and "stop" or "play"
	})
end)

RegisterCommand("cineanimlib",function(source,args)
	if source <= 0 or not hasStudioPermission(source) then return end
	local dict = args[1]
	local name = args[2]
	local loop = string.lower(args[3] or "") == "loop"
	if not validNativeName(dict) or not validNativeName(name) then
		notify(source,"aviso","Use: /cineanimlib dicionario animacao [loop]")
		return
	end
	TriggerClientEvent("cinematic_studio:sceneEvent",-1,{
		kind = "anim",
		actor = tostring(source),
		dict = dict,
		name = name,
		flag = loop and 1 or 49,
		action = "play"
	})
end)

RegisterCommand("cinefx",function(source,args)
	if source <= 0 or not hasStudioPermission(source) then return end
	local preset = string.lower(args[1] or "")
	if not fxPresets[preset] then
		notify(source,"aviso","Use: /cinefx explosao|fogo|fumaca|flash")
		return
	end
	TriggerClientEvent("cinematic_studio:placeFx",source,preset)
end)

RegisterCommand("cineptfx",function(source,args)
	if source <= 0 or not hasStudioPermission(source) then return end
	local preset = string.lower(args[1] or "")
	if not ptfxPresets[preset] then
		notify(source,"aviso","Use: /cineptfx faisca|fumaca|fogo|poeira")
		return
	end
	TriggerClientEvent("cinematic_studio:placeMarker",source,"ptfx",preset,{})
end)

RegisterCommand("cinesom",function(source,args)
	if source <= 0 or not hasStudioPermission(source) then return end
	local preset = string.lower(args[1] or "")
	if not soundPresets[preset] then
		notify(source,"aviso","Use: /cinesom corte|impacto|missao|entrada")
		return
	end
	TriggerClientEvent("cinematic_studio:placeMarker",source,"sound",preset,{})
end)

RegisterNetEvent("cinematic_studio:submitFx")
AddEventHandler("cinematic_studio:submitFx",function(preset,coords)
	local source = source
	if not hasStudioPermission(source) or not fxPresets[preset] or type(coords) ~= "table" then return end
	if type(coords.x) ~= "number" or type(coords.y) ~= "number" or type(coords.z) ~= "number" then return end
	TriggerClientEvent("cinematic_studio:sceneEvent",-1,{
		kind = "fx",
		preset = preset,
		coords = { x = coords.x, y = coords.y, z = coords.z }
	})
end)

RegisterNetEvent("cinematic_studio:submitMarker")
AddEventHandler("cinematic_studio:submitMarker",function(kind,preset,metadata,coords)
	local source = source
	if not hasStudioPermission(source) or type(coords) ~= "table" then return end
	if type(coords.x) ~= "number" or type(coords.y) ~= "number" or type(coords.z) ~= "number" then return end
	if kind == "ptfx" and not ptfxPresets[preset] then return end
	if kind == "sound" and not soundPresets[preset] then return end
	if kind ~= "ptfx" and kind ~= "sound" then return end
	TriggerClientEvent("cinematic_studio:sceneEvent",-1,{
		kind = kind,
		preset = preset,
		coords = { x = coords.x, y = coords.y, z = coords.z }
	})
end)

RegisterNetEvent("cinematic_studio:requestCharacterLooks")
AddEventHandler("cinematic_studio:requestCharacterLooks",function()
	local source = source
	if not hasStudioPermission(source) then return end
	-- looks are captured client-side in the new version, but return empty table to prevent crashes in old client event triggers
	TriggerClientEvent("cinematic_studio:characterLooks",source,{})
end)

RegisterNetEvent("cinematic_studio:saveTake")
AddEventHandler("cinematic_studio:saveTake",function(encodedTake)
	local source = source
	if not hasStudioPermission(source) or type(encodedTake) ~= "string" then return end

	if #encodedTake > 12000000 then
		notify(source,"negado","Cena muito grande para salvar. Grave uma tomada menor.")
		return
	end

	SaveResourceFile(GetCurrentResourceName(),"takes/user_" .. tostring(source) .. "_latest.json",encodedTake,-1)
	notify(source,"sucesso","Cena 3D salva no servidor.")
end)

RegisterNetEvent("cinematic_studio:loadTake")
AddEventHandler("cinematic_studio:loadTake",function()
	local source = source
	if not hasStudioPermission(source) then return end

	local encodedTake = LoadResourceFile(GetCurrentResourceName(),"takes/user_" .. tostring(source) .. "_latest.json")
	if encodedTake and encodedTake ~= "" then
		TriggerLatentClientEvent("cinematic_studio:takeLoaded",source,25000,encodedTake)
	else
		notify(source,"aviso","Nenhuma cena 3D salva para carregar.")
	end
end)


