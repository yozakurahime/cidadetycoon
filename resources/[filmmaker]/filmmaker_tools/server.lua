GlobalState.filmmakerActive = true

AddEventHandler("onResourceStop", function(resource)
	if resource == GetCurrentResourceName() then
		GlobalState.filmmakerActive = false
	end
end)

local props = {}
local nextPropId = 0
local maxProps = 250

local function isFilmmaker(source)
	if source == 0 then return true end
	
	-- Qbox group checks
	if GetResourceState("qbx_core") == "started" then
		return exports.qbx_core:HasGroup(source, "admin") 
			or exports.qbx_core:HasGroup(source, "god") 
			or exports.qbx_core:HasGroup(source, "filmmaker")
			or IsPlayerAceAllowed(source,"filmmaker.tools")
	-- QBCore fallback
	elseif GetResourceState("qb-core") == "started" then
		local QBCore = exports['qb-core']:GetCoreObject()
		return QBCore.Functions.HasPermission(source, "admin") 
			or QBCore.Functions.HasPermission(source, "god") 
			or QBCore.Functions.HasPermission(source, "filmmaker")
			or IsPlayerAceAllowed(source,"filmmaker.tools")
	else
		-- Standalone/Ace permission fallback
		return IsPlayerAceAllowed(source,"filmmaker.tools") or IsPlayerAceAllowed(source,"command")
	end
end

local function notify(source,kind,message)
    local notifyType = ({ sucesso = "success", negado = "error", aviso = "warning", importante = "inform" })[kind] or "inform"
    if GetResourceState("qbx_core") == "started" then
        exports.qbx_core:Notify(source, message, notifyType)
    else
        TriggerClientEvent("ox_lib:notify", source, { title = "Filmmaker", description = message, type = notifyType })
    end
end

local function canManageCrew(source)
	if source == 0 then return true end
	
	-- Qbox group checks
	if GetResourceState("qbx_core") == "started" then
		return exports.qbx_core:HasGroup(source, "admin") or exports.qbx_core:HasGroup(source, "god")
	-- QBCore fallback
	elseif GetResourceState("qb-core") == "started" then
		local QBCore = exports['qb-core']:GetCoreObject()
		return QBCore.Functions.HasPermission(source, "admin") or QBCore.Functions.HasPermission(source, "god")
	else
		-- Standalone/Ace permission fallback
		return IsPlayerAceAllowed(source, "command")
	end
end

local function validText(value,maxLength)
	return type(value) == "string" and #value > 0 and #value <= maxLength
end

local function validCoords(coords)
	return type(coords) == "table"
		and type(coords.x) == "number"
		and type(coords.y) == "number"
		and type(coords.z) == "number"
		and math.abs(coords.x) < 10000.0
		and math.abs(coords.y) < 10000.0
		and math.abs(coords.z) < 3000.0
end

RegisterCommand("filmhelp",function(source)
	if source <= 0 or not isFilmmaker(source) then return end
	TriggerClientEvent("filmmaker_tools:showHelp",source)
end)

RegisterCommand("darfilmmaker",function(source,args)
	if source <= 0 or not canManageCrew(source) then return end
	local target = tonumber(args[1])
	if not target or not GetPlayerName(target) then
		notify(source,"aviso","Use /darfilmmaker ID com o jogador online.")
		return
	end
	
	if GetResourceState("qbx_core") == "started" then
		ExecuteCommand(("add_principal player.%s group.filmmaker"):format(target))
	elseif GetResourceState("qb-core") == "started" then
		local QBCore = exports['qb-core']:GetCoreObject()
		local targetPlayer = QBCore.Functions.GetPlayer(target)
		if targetPlayer then
			targetPlayer.Functions.SetJob("filmmaker", 1)
		end
	else
		-- Standalone fallback
		ExecuteCommand(("add_principal identifier.license:%s group.filmmaker"):format(GetPlayerIdentifier(target, 0)))
	end
	
	notify(source,"sucesso","Cargo Filmmaker concedido ao ID " .. tostring(target) .. ".")
	notify(target,"sucesso","Voce agora faz parte da equipe Filmmaker. Use /filmhelp.")
end)

RegisterCommand("tirarfilmmaker",function(source,args)
	if source <= 0 or not canManageCrew(source) then return end
	local target = tonumber(args[1])
	if not target or not GetPlayerName(target) then
		notify(source,"aviso","Use /tirarfilmmaker ID com o jogador online.")
		return
	end
	
	if GetResourceState("qbx_core") == "started" then
		ExecuteCommand(("remove_principal player.%s group.filmmaker"):format(target))
	elseif GetResourceState("qb-core") == "started" then
		local QBCore = exports['qb-core']:GetCoreObject()
		local targetPlayer = QBCore.Functions.GetPlayer(target)
		if targetPlayer then
			targetPlayer.Functions.SetJob("unemployed", 0)
		end
	else
		-- Standalone fallback
		ExecuteCommand(("remove_principal identifier.license:%s group.filmmaker"):format(GetPlayerIdentifier(target, 0)))
	end
	
	notify(source,"sucesso","Cargo Filmmaker removido do ID " .. tostring(target) .. ".")
	notify(target,"aviso","Seu cargo Filmmaker foi removido.")
end)

RegisterCommand("claquete",function(source,args)
	if source <= 0 or not isFilmmaker(source) then return end

	local label = table.concat(args," ")
	if label == "" then label = "Nova tomada" end
	if #label > 70 then label = label:sub(1,70) end

	TriggerClientEvent("filmmaker_tools:slate",-1,label,GetPlayerName(source) or "Direcao")
end)

RegisterNetEvent("filmmaker_tools:requestProps")
AddEventHandler("filmmaker_tools:requestProps",function()
	TriggerClientEvent("filmmaker_tools:syncProps",source,props)
end)

RegisterNetEvent("filmmaker_tools:addProp")
AddEventHandler("filmmaker_tools:addProp",function(model,coords,heading)
	local source = source
	if not isFilmmaker(source) then return end
	if not validText(model,80) or not model:match("^[%w_]+$") or not validCoords(coords) then return end
	if type(heading) ~= "number" then heading = 0.0 end

	local count = 0
	for _ in pairs(props) do count = count + 1 end
	if count >= maxProps then
		notify(source,"negado","O set atingiu o limite de objetos de cena.")
		return
	end

	nextPropId = nextPropId + 1
	local id = tostring(nextPropId)
	props[id] = {
		id = id,
		model = model,
		coords = { x = coords.x, y = coords.y, z = coords.z },
		heading = heading % 360.0,
		author = GetPlayerName(source) or "Filmmaker"
	}
	TriggerClientEvent("filmmaker_tools:addProp",-1,props[id])
	notify(source,"sucesso","Objeto adicionado ao set.")
end)

RegisterNetEvent("filmmaker_tools:removeProp")
AddEventHandler("filmmaker_tools:removeProp",function(id)
	local source = source
	if not isFilmmaker(source) or type(id) ~= "string" or not props[id] then return end

	props[id] = nil
	TriggerClientEvent("filmmaker_tools:removeProp",-1,id)
	notify(source,"sucesso","Objeto removido do set.")
end)

RegisterNetEvent("filmmaker_tools:clearProps")
AddEventHandler("filmmaker_tools:clearProps",function()
	local source = source
	if not isFilmmaker(source) then return end

	props = {}
	TriggerClientEvent("filmmaker_tools:clearProps",-1)
	notify(source,"sucesso","Cenario limpo.")
end)

local lights = {}
local nextLightId = 0
local maxLights = 100

RegisterNetEvent("filmmaker_tools:requestLights")
AddEventHandler("filmmaker_tools:requestLights", function()
	TriggerClientEvent("filmmaker_tools:syncLights", source, lights)
end)

RegisterNetEvent("filmmaker_tools:addLight")
AddEventHandler("filmmaker_tools:addLight", function(coords, r, g, b, range, intensity)
	local source = source
	if not isFilmmaker(source) then return end
	if not validCoords(coords) then return end

	local count = 0
	for _ in pairs(lights) do count = count + 1 end
	if count >= maxLights then
		notify(source,"negado","O set atingiu o limite de luzes de cena.")
		return
	end

	nextLightId = nextLightId + 1
	local id = tostring(nextLightId)
	lights[id] = {
		id = id,
		coords = { x = coords.x, y = coords.y, z = coords.z },
		r = r or 255,
		g = g or 255,
		b = b or 255,
		range = range or 10.0,
		intensity = intensity or 5.0,
		author = GetPlayerName(source) or "Filmmaker"
	}
	TriggerClientEvent("filmmaker_tools:addLight", -1, lights[id])
	notify(source,"sucesso","Luz adicionada ao set.")
end)

RegisterNetEvent("filmmaker_tools:removeLight")
AddEventHandler("filmmaker_tools:removeLight", function(id)
	local source = source
	if not isFilmmaker(source) or type(id) ~= "string" or not lights[id] then return end

	lights[id] = nil
	TriggerClientEvent("filmmaker_tools:removeLight", -1, id)
	notify(source,"sucesso","Luz removida do set.")
end)

RegisterNetEvent("filmmaker_tools:clearLights")
AddEventHandler("filmmaker_tools:clearLights", function()
	local source = source
	if not isFilmmaker(source) then return end

	lights = {}
	TriggerClientEvent("filmmaker_tools:clearLights", -1)
	notify(source,"sucesso","Todas as luzes limpas.")
end)

RegisterNetEvent("filmmaker_tools:syncWeather")
AddEventHandler("filmmaker_tools:syncWeather", function(weatherType)
	local source = source
	if not isFilmmaker(source) then return end
	
	if GetResourceState("Renewed-Weathersync") == "started" then
		exports['Renewed-Weathersync']:setWeather(weatherType)
	elseif GetResourceState("qb-weathersync") == "started" then
		TriggerEvent("qb-weathersync:server:setWeatherState", weatherType)
	end
	
	TriggerClientEvent("filmmaker_tools:clientSetWeather", -1, weatherType)
end)

RegisterNetEvent("filmmaker_tools:syncTime")
AddEventHandler("filmmaker_tools:syncTime", function(hours, minutes, freeze)
	local source = source
	if not isFilmmaker(source) then return end
	
	if GetResourceState("Renewed-Weathersync") == "started" then
		exports['Renewed-Weathersync']:setTime(hours, minutes)
		exports['Renewed-Weathersync']:setFreeze(freeze == true)
	elseif GetResourceState("qb-weathersync") == "started" then
		TriggerEvent("qb-weathersync:server:setTime", hours, minutes)
	end
	
	TriggerClientEvent("filmmaker_tools:clientSetTime", -1, hours, minutes, freeze)
end)


