local tools = {
	cleanMode = false,
	props = {},
	placing = nil,
	slate = nil,
	npcDensity = 1.0,
	lights = {}
}

local isTimeFrozen = false
local frozenHours = 12
local frozenMinutes = 0
local activeCam = nil
local camFov = 40.0
local lastNPCClean = 0

local function notify(kind,message)
    local notifyType = ({ sucesso = "success", negado = "error", aviso = "warning", importante = "inform" })[kind] or "inform"
    if GetResourceState("qbx_core") == "started" then
        exports.qbx_core:Notify(message, notifyType)
    else
        TriggerEvent("ox_lib:notify", { title = "Filmmaker", description = message, type = notifyType })
    end
end

local function chat(message)
	TriggerEvent("chat:addMessage",{
		color = { 224, 185, 105 },
		args = { "[Cidade Tycoon]", message }
	})
end

local function drawText(x,y,text,scale,center,r,g,b,a)
	SetTextFont(4)
	SetTextScale(scale,scale)
	SetTextColour(r or 255,g or 255,b or 255,a or 255)
	SetTextCentre(center == true)
	SetTextOutline()
	BeginTextCommandDisplayText("STRING")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(x,y)
end

local function rotationDirection(rotation)
	local z = math.rad(rotation.z)
	local x = math.rad(rotation.x)
	local horizontal = math.abs(math.cos(x))
	return vector3(-math.sin(z) * horizontal,math.cos(z) * horizontal,math.sin(x))
end

local function cameraHitPosition(distance)
	local origin = GetGameplayCamCoord()
	local direction = rotationDirection(GetGameplayCamRot(2))
	local destination = origin + (direction * distance)
	local ray = StartShapeTestRay(origin.x,origin.y,origin.z,destination.x,destination.y,destination.z,-1,PlayerPedId(),7)
	local _,hit,coords = GetShapeTestResult(ray)
	if hit == 1 then return coords end
	return destination
end

local function loadModel(model)
	local hash = GetHashKey(model)
	if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
	RequestModel(hash)
	local expires = GetGameTimer() + 5000
	while not HasModelLoaded(hash) and GetGameTimer() < expires do
		Citizen.Wait(0)
	end
	if not HasModelLoaded(hash) then return nil end
	return hash
end

local function removeLocalProp(id)
	local entity = tools.props[id]
	if entity and DoesEntityExist(entity) then
		DeleteObject(entity)
		DeleteEntity(entity)
	end
	tools.props[id] = nil
end

local function createLocalProp(data)
	if type(data) ~= "table" or not data.id or not data.model or not data.coords then return end
	removeLocalProp(data.id)

	local hash = loadModel(data.model)
	if not hash then return end
	local coords = data.coords
	local entity = CreateObjectNoOffset(hash,coords.x + 0.0,coords.y + 0.0,coords.z + 0.0,false,false,false)
	if entity and entity ~= 0 then
		SetEntityHeading(entity,(data.heading or 0.0) + 0.0)
		FreezeEntityPosition(entity,true)
		SetEntityCollision(entity,true,true)
		SetEntityAsMissionEntity(entity,true,true)
		tools.props[data.id] = entity
		TriggerEvent("cinematic_studio:trackEntity","prop",entity)
	end
	SetModelAsNoLongerNeeded(hash)
end

local function cancelPlacement()
	if tools.placing and tools.placing.entity and DoesEntityExist(tools.placing.entity) then
		DeleteObject(tools.placing.entity)
		DeleteEntity(tools.placing.entity)
	end
	tools.placing = nil
end

local function beginPlacement(model)
	if tools.placing then cancelPlacement() end
	local hash = loadModel(model)
	if not hash then
		notify("negado","Modelo de objeto invalido ou indisponivel.")
		return
	end

	local coords = cameraHitPosition(12.0)
	local entity = CreateObjectNoOffset(hash,coords.x,coords.y,coords.z,false,false,false)
	SetEntityAlpha(entity,180,false)
	SetEntityCollision(entity,false,false)
	FreezeEntityPosition(entity,true)
	tools.placing = {
		entity = entity,
		model = model,
		heading = GetEntityHeading(PlayerPedId()),
		height = 0.0
	}
	SetModelAsNoLongerNeeded(hash)
	notify("importante","Posicionando objeto: ENTER confirma, BACKSPACE cancela.")
end

RegisterNetEvent("filmmaker_tools:syncProps")
AddEventHandler("filmmaker_tools:syncProps",function(props)
	for id in pairs(tools.props) do removeLocalProp(id) end
	for _,data in pairs(props or {}) do createLocalProp(data) end
end)

RegisterNetEvent("filmmaker_tools:addProp")
AddEventHandler("filmmaker_tools:addProp",createLocalProp)

RegisterNetEvent("filmmaker_tools:removeProp")
AddEventHandler("filmmaker_tools:removeProp",removeLocalProp)

RegisterNetEvent("filmmaker_tools:clearProps")
AddEventHandler("filmmaker_tools:clearProps",function()
	for id in pairs(tools.props) do removeLocalProp(id) end
end)

RegisterNetEvent("filmmaker_tools:showHelp")
AddEventHandler("filmmaker_tools:showHelp",function()
	chat("/cinehud - HUD limpo para gravacao | /claquete Cena 1 Take 1 - contagem sincronizada")
	chat("/cineprop nome_do_modelo - posicionar objeto | /cineapagar - remover objeto mirado | /cinelimpar - limpar set")
	chat("/npcs [0-100] - controlar densidade de NPCs/veiculos (sem valor alterna liga/desliga)")
	chat("Rockstar: /rec inicia/salva o clipe e /cancelar descarta. Exporte pelo Editor de Replays com EVER.")
end)

RegisterNetEvent("filmmaker_tools:slate")
AddEventHandler("filmmaker_tools:slate",function(label,director)
	tools.slate = {
		label = label,
		director = director,
		started = GetGameTimer(),
		ends = GetGameTimer() + 4600
	}
	PlaySoundFrontend(-1,"SELECT","HUD_FRONTEND_DEFAULT_SOUNDSET",true)
end)

RegisterCommand("cinehud",function()
	tools.cleanMode = not tools.cleanMode
	DisplayHud(not tools.cleanMode)
	DisplayRadar(not tools.cleanMode)
	TriggerEvent("hudOff",tools.cleanMode)
	notify("sucesso",tools.cleanMode and "Modo captura limpa ativado." or "HUD restaurada.")
end,false)

RegisterCommand("cineprop",function(_,args)
	local model = args[1]
	if not model then
		chat("Uso: /cineprop nome_do_modelo. Exemplo: /cineprop prop_barrier_work05")
		return
	end
	beginPlacement(model)
end,false)

RegisterCommand("cineapagar",function()
	local target = cameraHitPosition(100.0)
	local bestId = nil
	local bestDistance = 3.0
	for id,entity in pairs(tools.props) do
		if DoesEntityExist(entity) then
			local distance = #(GetEntityCoords(entity) - target)
			if distance < bestDistance then
				bestId = id
				bestDistance = distance
			end
		end
	end
	if bestId then
		TriggerServerEvent("filmmaker_tools:removeProp",bestId)
	else
		notify("aviso","Mire em um objeto do set para remover.")
	end
end,false)

RegisterCommand("cinelimpar",function()
	TriggerServerEvent("filmmaker_tools:clearProps")
end,false)

RegisterCommand("npcs", function(_, args)
	local amount = args[1]
	local clearArea = false

	if not amount then
		-- Toggle between 0.0 and 1.0
		if tools.npcDensity > 0.0 then
			tools.npcDensity = 0.0
			clearArea = true
			notify("sucesso", "Todos os NPCs e veiculos ambientais foram desativados.")
		else
			tools.npcDensity = 1.0
			notify("sucesso", "Todos os NPCs e veiculos ambientais foram ativados (100%).")
		end
	else
		local val = tonumber(amount)
		if not val or val < 0 or val > 100 then
			chat("Uso: /npcs [0-100] (Exemplo: /npcs 50 para 50% de densidade, ou apenas /npcs para ativar/desativar)")
			return
		end
		
		tools.npcDensity = val / 100.0
		if val == 0 then
			clearArea = true
			notify("sucesso", "Todos os NPCs e veiculos ambientais foram desativados.")
		else
			notify("sucesso", string.format("Densidade de NPCs e veiculos ambientais definida para %d%%.", val))
		end
	end

	if clearArea then
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		ClearAreaOfPeds(coords.x, coords.y, coords.z, 300.0, 1)
		ClearAreaOfVehicles(coords.x, coords.y, coords.z, 300.0, false, false, false, false, false)
	end
end, false)

Citizen.CreateThread(function()
	Citizen.Wait(2500)
	TriggerServerEvent("filmmaker_tools:requestProps")
end)

Citizen.CreateThread(function()
	while true do
		local sleep = 500
		
		if tools.npcDensity ~= nil then
			sleep = 0
			SetPedDensityMultiplierThisFrame(tools.npcDensity)
			SetVehicleDensityMultiplierThisFrame(tools.npcDensity)
			SetRandomVehicleDensityMultiplierThisFrame(tools.npcDensity)
			SetScenarioPedDensityMultiplierThisFrame(tools.npcDensity)
			SetParkedVehicleDensityMultiplierThisFrame(tools.npcDensity)
		end

		if tools.cleanMode then
			sleep = 0
			HideHudAndRadarThisFrame()
			for component = 1,22 do HideHudComponentThisFrame(component) end
		end

		if tools.placing then
			sleep = 0
			local placing = tools.placing
			local coords = cameraHitPosition(40.0) + vector3(0.0,0.0,placing.height)
			SetEntityCoordsNoOffset(placing.entity,coords.x,coords.y,coords.z,false,false,false)
			SetEntityHeading(placing.entity,placing.heading)

			if IsControlPressed(0,174) then placing.heading = placing.heading + 1.2 end
			if IsControlPressed(0,175) then placing.heading = placing.heading - 1.2 end
			if IsControlPressed(0,172) then placing.height = placing.height + 0.015 end
			if IsControlPressed(0,173) then placing.height = placing.height - 0.015 end
			if IsControlJustPressed(0,191) then
				TriggerServerEvent("filmmaker_tools:addProp",placing.model,{
					x = coords.x,
					y = coords.y,
					z = coords.z
				},placing.heading)
				cancelPlacement()
			elseif IsControlJustPressed(0,177) then
				cancelPlacement()
				notify("aviso","Posicionamento cancelado.")
			end

			drawText(0.5,0.91,"~w~SET: ~y~ENTER~w~ confirmar  ~y~SETAS~w~ girar/altura  ~y~BACKSPACE~w~ cancelar",0.36,true)
		end

		-- Dynamic pool clean loop for /npcs 0
		if tools.npcDensity == 0.0 and GetGameTimer() - lastNPCClean > 500 then
			lastNPCClean = GetGameTimer()
			
			-- Wipe peds
			local peds = GetGamePool('CPed')
			for i = 1, #peds do
				local ped = peds[i]
				if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
					local isGhostPed = false
					pcall(function()
						isGhostPed = exports['cidade_ghost']:IsGhostEntity(ped)
					end)
					if not isGhostPed then
						DeleteEntity(ped)
					end
				end
			end
			
			-- Wipe vehicles
			local vehicles = GetGamePool('CVehicle')
			for i = 1, #vehicles do
				local veh = vehicles[i]
				if DoesEntityExist(veh) then
					local isGhostVeh = false
					pcall(function()
						isGhostVeh = exports['cidade_ghost']:IsGhostEntity(veh)
					end)
					local hasPlayer = false
					for _, player in ipairs(GetActivePlayers()) do
						local pPed = GetPlayerPed(player)
						if GetVehiclePedIsIn(pPed, false) == veh then
							hasPlayer = true
							break
						end
					end
					if not isGhostVeh and not hasPlayer then
						DeleteEntity(veh)
					end
				end
			end
		end

		-- Draw dynamic lights
		for id, light in pairs(tools.lights) do
			DrawLightWithRange(light.coords.x, light.coords.y, light.coords.z, light.r, light.g, light.b, light.range + 0.0, light.intensity + 0.0)
			
			-- Render visual sphere when cleanMode is off
			if not tools.cleanMode then
				DrawMarker(28, light.coords.x, light.coords.y, light.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, light.r, light.g, light.b, 200, false, false, 2, false, nil, nil, false)
			end
		end

		-- Enforce frozen clock time
		if isTimeFrozen then
			NetworkOverrideClockTime(frozenHours, frozenMinutes, 0)
		end

		if tools.slate and tools.slate.ends > GetGameTimer() then
			sleep = 0
			local elapsed = GetGameTimer() - tools.slate.started
			local count = elapsed < 1000 and "3" or (elapsed < 2000 and "2" or (elapsed < 3000 and "1" or "ACAO"))
			DrawRect(0.5,0.5,0.42,0.2,6,8,12,225)
			drawText(0.5,0.445,"Cidade Tycoon | " .. tools.slate.label,0.38,true,224,185,105,255)
			drawText(0.5,0.49,count,0.8,true,255,255,255,255)
			drawText(0.5,0.56,"Direcao: " .. tools.slate.director,0.30,true,180,185,194,255)
		elseif tools.slate then
			tools.slate = nil
		end
		Citizen.Wait(sleep)
	end
end)

-- Synced Lights Event Listeners
RegisterNetEvent("filmmaker_tools:syncLights")
AddEventHandler("filmmaker_tools:syncLights", function(syncedLights)
	tools.lights = syncedLights or {}
end)

RegisterNetEvent("filmmaker_tools:addLight")
AddEventHandler("filmmaker_tools:addLight", function(light)
	tools.lights[light.id] = light
end)

RegisterNetEvent("filmmaker_tools:removeLight")
AddEventHandler("filmmaker_tools:removeLight", function(id)
	tools.lights[id] = nil
end)

RegisterNetEvent("filmmaker_tools:clearLights")
AddEventHandler("filmmaker_tools:clearLights", function()
	tools.lights = {}
end)

-- Weather / Time sync listeners
RegisterNetEvent("filmmaker_tools:clientSetWeather")
AddEventHandler("filmmaker_tools:clientSetWeather", function(weatherType)
	ClearOverrideWeather()
	ClearWeatherTypePersist()
	SetWeatherTypeNowPersist(weatherType)
	SetWeatherTypeNow(weatherType)
	SetWeatherTypePersist(weatherType)
	notify("sucesso", "Clima do set alterado para: " .. weatherType)
end)

RegisterNetEvent("filmmaker_tools:clientSetTime")
AddEventHandler("filmmaker_tools:clientSetTime", function(hours, minutes, freeze)
	NetworkOverrideClockTime(hours, minutes, 0)
	isTimeFrozen = freeze
	frozenHours = hours
	frozenMinutes = minutes
	notify("sucesso", string.format("Tempo do set alterado para: %02d:%02d%s", hours, minutes, freeze and " (Congelado)" or ""))
end)

-- Lights Spawning Commands
RegisterCommand("cineluz", function(_, args)
	local r = tonumber(args[1]) or 255
	local g = tonumber(args[2]) or 255
	local b = tonumber(args[3]) or 255
	local range = tonumber(args[4]) or 10.0
	local intensity = tonumber(args[5]) or 5.0

	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	TriggerServerEvent("filmmaker_tools:addLight", { x = coords.x, y = coords.y, z = coords.z }, r, g, b, range, intensity)
end, false)

RegisterCommand("cineapagarluz", function()
	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	local bestId = nil
	local bestDistance = 5.0
	for id, light in pairs(tools.lights) do
		local lightCoords = vector3(light.coords.x, light.coords.y, light.coords.z)
		local distance = #(coords - lightCoords)
		if distance < bestDistance then
			bestId = id
			bestDistance = distance
		end
	end
	if bestId then
		TriggerServerEvent("filmmaker_tools:removeLight", bestId)
	else
		notify("aviso", "Nenhuma luz prÃ³xima (raio de 5m) para apagar.")
	end
end, false)

RegisterCommand("cinelimparluz", function()
	TriggerServerEvent("filmmaker_tools:clearLights")
end, false)

-- Pursuit Camera Commands
RegisterCommand("cinecam", function()
	if activeCam then
		DestroyCam(activeCam, false)
		RenderScriptCams(false, false, 0, 1, 0)
		activeCam = nil
		notify("sucesso", "CÃ¢mera de perseguiÃ§Ã£o desativada.")
	else
		local ped = PlayerPedId()
		local playerCoords = GetEntityCoords(ped)
		
		local vehicles = GetGamePool('CVehicle')
		local closestVeh = nil
		local minDistance = 250.0
		for i=1, #vehicles do
			local veh = vehicles[i]
			if DoesEntityExist(veh) then
				local dist = #(playerCoords - GetEntityCoords(veh))
				if dist < minDistance then
					closestVeh = veh
					minDistance = dist
				end
			end
		end
		
		if closestVeh then
			local camCoords = GetGameplayCamCoord()
			activeCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camCoords.x, camCoords.y, camCoords.z + 1.5, 0.0, 0.0, 0.0, camFov, true, 2)
			PointCamAtEntity(activeCam, closestVeh, 0.0, 0.0, 0.0, true)
			RenderScriptCams(true, true, 500, true, true)
			notify("sucesso", "CÃ¢mera de perseguiÃ§Ã£o ativada! Rastreando viatura prÃ³xima.")
		else
			notify("aviso", "Nenhum veÃ­culo prÃ³ximo para rastrear.")
		end
	end
end, false)

RegisterCommand("cinecamfov", function(_, args)
	local fov = tonumber(args[1])
	if not fov or fov < 5.0 or fov > 120.0 then
		chat("Uso: /cinecamfov [5-120] (Ajusta o zoom da cÃ¢mera)")
		return
	end
	camFov = fov + 0.0
	if activeCam and DoesCamExist(activeCam) then
		SetCamFov(activeCam, camFov)
	end
	notify("sucesso", "FOV da cÃ¢mera definido para: " .. tostring(camFov))
end, false)

-- Initial light sync request
Citizen.CreateThread(function()
	Citizen.Wait(3000)
	TriggerServerEvent("filmmaker_tools:requestLights")
end)

AddEventHandler("onResourceStop",function(resource)
	if resource ~= GetCurrentResourceName() then return end
	cancelPlacement()
	for id in pairs(tools.props) do removeLocalProp(id) end
	if activeCam then
		DestroyCam(activeCam, false)
		RenderScriptCams(false, false, 0, 1, 0)
	end
	if tools.cleanMode then
		DisplayHud(true)
		DisplayRadar(true)
		TriggerEvent("hudOff",false)
	end
end)




