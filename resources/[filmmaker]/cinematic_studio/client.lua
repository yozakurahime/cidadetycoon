local studio = {
	active = false,
	panel = false,
	playing = false,
	cam = nil,
	coords = nil,
	rotation = nil,
	fov = 50.0,
	speed = 8.0,
	hiddenPed = false,
	letterbox = true,
	dof = false,
	dofNear = 1.0,
	dofFar = 12.0,
	dofStrength = 0.6,
	easing = "smooth",
	duration = 3000,
	renderRate = 1.0,
	targetKey = nil,
	targetEntity = nil,
	targetLabel = nil,
	keyframes = {}
}

local function notify(kind,message)
    local notifyType = ({ sucesso = "success", negado = "error", aviso = "warning", importante = "inform" })[kind] or "inform"
    if GetResourceState("qbx_core") == "started" then
        exports.qbx_core:Notify(message, notifyType)
    else
        TriggerEvent("ox_lib:notify", { title = "Cinematic Studio", description = message, type = notifyType })
    end
end

local function vecToTable(value)
	return { x = value.x, y = value.y, z = value.z }
end

local function tableToVec(value)
	return vector3(value.x + 0.0,value.y + 0.0,value.z + 0.0)
end

local function directionFromRotation(rotation)
	local heading = math.rad(rotation.z)
	local pitch = math.rad(rotation.x)
	local horizontal = math.abs(math.cos(pitch))
	return vector3(-math.sin(heading) * horizontal,math.cos(heading) * horizontal,math.sin(pitch))
end

local function rightFromRotation(rotation)
	local heading = math.rad(rotation.z)
	return vector3(math.cos(heading),math.sin(heading),0.0)
end

local function clamp(value,minValue,maxValue)
	return math.max(minValue,math.min(maxValue,value))
end

local function lerp(startValue,endValue,amount)
	return startValue + ((endValue - startValue) * amount)
end

local function angleLerp(startValue,endValue,amount)
	local difference = ((endValue - startValue + 180.0) % 360.0) - 180.0
	return startValue + (difference * amount)
end

local function smoothStep(amount)
	return amount * amount * (3.0 - (2.0 * amount))
end

local function applyDof()
	if not studio.cam then return end
	SetCamUseShallowDofMode(studio.cam,studio.dof)
	if studio.dof then
		SetCamNearDof(studio.cam,studio.dofNear)
		SetCamFarDof(studio.cam,studio.dofFar)
		SetCamDofStrength(studio.cam,studio.dofStrength)
		SetUseHiDof()
	end
end

local function updatePanel()
	SendNUIMessage({
		action = "state",
		active = studio.active,
		playing = studio.playing,
		fov = studio.fov,
		speed = studio.speed,
		duration = studio.duration,
		easing = studio.easing,
		dof = studio.dof,
		dofNear = studio.dofNear,
		dofFar = studio.dofFar,
		dofStrength = studio.dofStrength,
		letterbox = studio.letterbox,
		targetKey = studio.targetKey,
		targetLabel = studio.targetLabel,
		keyframes = studio.keyframes
	})
end

local function setPanel(open)
	studio.panel = open
	SetNuiFocus(open,open)
	SendNUIMessage({ action = "visible", visible = open })
	if open then
		updatePanel()
		TriggerEvent("cinematic_studio:requestReplayState")
	end
end

local function setCamTransform(coords,rotation,fov)
	studio.coords = coords
	studio.rotation = rotation
	studio.fov = fov
	SetCamCoord(studio.cam,coords.x,coords.y,coords.z)
	SetCamRot(studio.cam,rotation.x,rotation.y,rotation.z,2)
	SetCamFov(studio.cam,fov)
	if studio.targetEntity and DoesEntityExist(studio.targetEntity) then
		PointCamAtEntity(studio.cam,studio.targetEntity,0.0,0.0,0.65,true)
	else
		StopCamPointing(studio.cam)
	end
	SetFocusPosAndVel(coords.x,coords.y,coords.z,0.0,0.0,0.0)
	applyDof()
end

local function serializeCurrentFrame()
	return {
		coords = vecToTable(studio.coords),
		rotation = vecToTable(studio.rotation),
		fov = studio.fov,
		duration = studio.duration,
		easing = studio.easing,
		dof = studio.dof,
		dofNear = studio.dofNear,
		dofFar = studio.dofFar,
		dofStrength = studio.dofStrength,
		targetKey = studio.targetKey,
		targetLabel = studio.targetLabel
	}
end

local function moveToFrame(frame)
	studio.dof = frame.dof or false
	studio.dofNear = frame.dofNear or 1.0
	studio.dofFar = frame.dofFar or 12.0
	studio.dofStrength = frame.dofStrength or 0.6
	studio.targetKey = frame.targetKey
	TriggerEvent("cinematic_studio:resolveCameraTarget",studio.targetKey)
	setCamTransform(tableToVec(frame.coords),tableToVec(frame.rotation),frame.fov or 50.0)
	updatePanel()
end

RegisterNetEvent("cinematic_studio:cameraTarget")
AddEventHandler("cinematic_studio:cameraTarget",function(key,entity,label)
	studio.targetKey = key
	studio.targetEntity = entity
	studio.targetLabel = label
	if studio.cam then
		setCamTransform(studio.coords,studio.rotation,studio.fov)
	end
	updatePanel()
end)

AddEventHandler("cinematic_studio:playbackSettings",function(rate)
	studio.renderRate = clamp(tonumber(rate) or 1.0,0.1,2.0)
end)

local function exitStudio()
	if not studio.active then return end
	studio.playing = false
	setPanel(false)
	RenderScriptCams(false,true,500,true,true)
	DestroyCam(studio.cam,false)
	ClearFocus()
	local ped = PlayerPedId()
	FreezeEntityPosition(ped,false)
	SetEntityVisible(ped,not studio.hiddenPed,true)
	DisplayHud(true)
	DisplayRadar(true)
	TriggerEvent("hudOff",false)
	studio.active = false
	studio.cam = nil
	studio.targetEntity = nil
	TriggerEvent("cinematic_studio:editorClosed")
	notify("importante","Cinematic Studio encerrado.")
end

local function enterStudio()
	if studio.active then
		setPanel(not studio.panel)
		return
	end
	local ped = PlayerPedId()
	studio.coords = GetGameplayCamCoord()
	studio.rotation = GetGameplayCamRot(2)
	studio.fov = GetGameplayCamFov()
	studio.hiddenPed = not IsEntityVisible(ped)
	studio.cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA",studio.coords.x,studio.coords.y,studio.coords.z,studio.rotation.x,studio.rotation.y,studio.rotation.z,studio.fov,true,2)
	studio.active = true
	SetCamActive(studio.cam,true)
	RenderScriptCams(true,true,500,true,true)
	FreezeEntityPosition(ped,true)
	SetEntityVisible(ped,false,true)
	DisplayHud(false)
	DisplayRadar(false)
	TriggerEvent("hudOff",true)
	applyDof()
	TriggerEvent("cinematic_studio:editorOpened")
	setPanel(true)
	notify("sucesso","Cinematic Studio aberto. Edite as cameras do replay e grave a tomada final com ALT+F9.")
end

local function playSequence()
	if studio.playing or #studio.keyframes == 0 then return end
	studio.playing = true
	setPanel(false)
	moveToFrame(studio.keyframes[1])
	TriggerEvent("cinematic_studio:cameraSequenceStarted")

	Citizen.CreateThread(function()
		for index = 2,#studio.keyframes do
			if not studio.playing or not studio.active then break end
			local from = studio.keyframes[index - 1]
			local to = studio.keyframes[index]
			local started = GetGameTimer()
			local duration = math.max(100,(to.duration or 3000) / studio.renderRate)
			studio.targetKey = to.targetKey
			TriggerEvent("cinematic_studio:resolveCameraTarget",studio.targetKey)
			if to.easing == "cut" then
				moveToFrame(to)
				while studio.playing and studio.active and GetGameTimer() - started < duration do
					Citizen.Wait(0)
				end
			else
				while studio.playing and studio.active do
					local amount = clamp((GetGameTimer() - started) / duration,0.0,1.0)
					local eased = to.easing == "linear" and amount or smoothStep(amount)
					local aCoords = tableToVec(from.coords)
					local bCoords = tableToVec(to.coords)
					local aRotation = tableToVec(from.rotation)
					local bRotation = tableToVec(to.rotation)
					local coords = vector3(lerp(aCoords.x,bCoords.x,eased),lerp(aCoords.y,bCoords.y,eased),lerp(aCoords.z,bCoords.z,eased))
					local rotation = vector3(angleLerp(aRotation.x,bRotation.x,eased),angleLerp(aRotation.y,bRotation.y,eased),angleLerp(aRotation.z,bRotation.z,eased))
					studio.dof = to.dof or false
					studio.dofNear = lerp(from.dofNear or 1.0,to.dofNear or 1.0,eased)
					studio.dofFar = lerp(from.dofFar or 12.0,to.dofFar or 12.0,eased)
					studio.dofStrength = lerp(from.dofStrength or 0.6,to.dofStrength or 0.6,eased)
					setCamTransform(coords,rotation,lerp(from.fov or 50.0,to.fov or 50.0,eased))
					if amount >= 1.0 then break end
					Citizen.Wait(0)
				end
			end
		end

		studio.playing = false
		TriggerEvent("cinematic_studio:cameraSequenceStopped")
		if studio.active then
			notify("sucesso","Tomada finalizada. ALT+F9 encerra a gravacao.")
			updatePanel()
		end
	end)
end

RegisterNetEvent("cinematic_studio:toggle")
AddEventHandler("cinematic_studio:toggle",function()
	if studio.active then
		exitStudio()
	else
		enterStudio()
	end
end)

RegisterCommand("studio_panel",function()
	if studio.active then
		setPanel(not studio.panel)
	end
end,false)
RegisterKeyMapping("studio_panel","Cinematic Studio: painel","keyboard","F6")

RegisterNUICallback("closePanel",function(_,callback)
	setPanel(false)
	callback({ ok = true })
end)

RegisterNUICallback("exit",function(_,callback)
	exitStudio()
	callback({ ok = true })
end)

RegisterNUICallback("setting",function(data,callback)
	local key = data.key
	local value = data.value
	if key == "fov" then
		studio.fov = clamp(tonumber(value) or studio.fov,10.0,100.0)
		SetCamFov(studio.cam,studio.fov)
	elseif key == "speed" then
		studio.speed = clamp(tonumber(value) or studio.speed,0.2,80.0)
	elseif key == "duration" then
		studio.duration = math.floor(clamp(tonumber(value) or studio.duration,100,60000))
	elseif key == "easing" then
		studio.easing = value == "linear" and "linear" or (value == "cut" and "cut" or "smooth")
	elseif key == "letterbox" then
		studio.letterbox = value == true
	elseif key == "dof" then
		studio.dof = value == true
	elseif key == "dofNear" then
		studio.dofNear = clamp(tonumber(value) or studio.dofNear,0.1,100.0)
	elseif key == "dofFar" then
		studio.dofFar = clamp(tonumber(value) or studio.dofFar,0.1,300.0)
	elseif key == "dofStrength" then
		studio.dofStrength = clamp(tonumber(value) or studio.dofStrength,0.0,1.0)
	end
	applyDof()
	updatePanel()
	callback({ ok = true })
end)

RegisterNUICallback("addFrame",function(_,callback)
	studio.keyframes[#studio.keyframes + 1] = serializeCurrentFrame()
	updatePanel()
	notify("sucesso","Keyframe adicionado.")
	callback({ ok = true })
end)

RegisterNUICallback("cameraPreset",function(data,callback)
	if not studio.targetEntity or not DoesEntityExist(studio.targetEntity) then
		notify("aviso","Escolha um ator, veiculo ou objeto como alvo primeiro.")
		callback({ ok = false })
		return
	end
	local preset = data.preset or "medium"
	local offsets = {
		close = vector3(0.75,-1.55,1.1),
		medium = vector3(1.5,-3.6,1.45),
		wide = vector3(3.6,-8.0,2.5),
		profile = vector3(4.0,0.1,1.25),
		reverse = vector3(-2.0,3.5,1.3)
	}
	local offset = offsets[preset] or offsets.medium
	studio.coords = GetOffsetFromEntityInWorldCoords(studio.targetEntity,offset.x,offset.y,offset.z)
	setCamTransform(studio.coords,studio.rotation,studio.fov)
	updatePanel()
	callback({ ok = true })
end)

RegisterNUICallback("goFrame",function(data,callback)
	local frame = studio.keyframes[tonumber(data.index)]
	if frame then moveToFrame(frame) end
	callback({ ok = true })
end)

RegisterNUICallback("deleteFrame",function(data,callback)
	local index = tonumber(data.index)
	if index and studio.keyframes[index] then
		table.remove(studio.keyframes,index)
		updatePanel()
	end
	callback({ ok = true })
end)

RegisterNUICallback("clearFrames",function(_,callback)
	studio.keyframes = {}
	updatePanel()
	callback({ ok = true })
end)

RegisterNUICallback("play",function(_,callback)
	playSequence()
	callback({ ok = true })
end)

RegisterNUICallback("exportFrame",function(_,callback)
	if not studio.active then
		callback({ ok = false })
		return
	end
	setPanel(false)
	Citizen.SetTimeout(300,function()
		TriggerServerEvent("cinematic_studio:exportFrame")
	end)
	callback({ ok = true })
end)

RegisterNUICallback("stop",function(_,callback)
	studio.playing = false
	TriggerEvent("cinematic_studio:cameraSequenceStopped")
	updatePanel()
	callback({ ok = true })
end)

RegisterNUICallback("save",function(_,callback)
	SetResourceKvp("cinematic_studio_project",json.encode(studio.keyframes))
	notify("sucesso","Tomada salva neste computador.")
	callback({ ok = true })
end)

RegisterNUICallback("load",function(_,callback)
	local saved = GetResourceKvpString("cinematic_studio_project")
	if saved and saved ~= "" then
		studio.keyframes = json.decode(saved) or {}
		updatePanel()
		notify("sucesso","Tomada carregada.")
	else
		notify("aviso","Nenhuma tomada salva.")
	end
	callback({ ok = true })
end)

AddEventHandler("onResourceStop",function(resource)
	if resource == GetCurrentResourceName() then
		exitStudio()
	end
end)

Citizen.CreateThread(function()
	while true do
		if studio.active then
			HideHudAndRadarThisFrame()
			if studio.letterbox then
				DrawRect(0.5,0.035,1.0,0.07,0,0,0,255)
				DrawRect(0.5,0.965,1.0,0.07,0,0,0,255)
			end

			if not studio.panel and not studio.playing then
				DisableControlAction(0,1,true)
				DisableControlAction(0,2,true)
				local amount = studio.speed * GetFrameTime()
				if IsControlPressed(0,21) then
					amount = amount * 4.0
				elseif IsControlPressed(0,36) then
					amount = amount * 0.2
				end

				local mouseX = GetDisabledControlNormal(0,1)
				local mouseY = GetDisabledControlNormal(0,2)
				studio.rotation = vector3(clamp(studio.rotation.x - (mouseY * 8.0),-89.0,89.0),0.0,studio.rotation.z - (mouseX * 8.0))
				local forward = directionFromRotation(studio.rotation)
				local right = rightFromRotation(studio.rotation)

				if IsControlPressed(0,32) then studio.coords = studio.coords + (forward * amount) end
				if IsControlPressed(0,33) then studio.coords = studio.coords - (forward * amount) end
				if IsControlPressed(0,35) then studio.coords = studio.coords + (right * amount) end
				if IsControlPressed(0,34) then studio.coords = studio.coords - (right * amount) end
				if IsControlPressed(0,38) then studio.coords = studio.coords + vector3(0.0,0.0,amount) end
				if IsControlPressed(0,44) then studio.coords = studio.coords - vector3(0.0,0.0,amount) end
				if IsControlJustPressed(0,241) then studio.fov = clamp(studio.fov - 2.0,10.0,100.0) end
				if IsControlJustPressed(0,242) then studio.fov = clamp(studio.fov + 2.0,10.0,100.0) end
				setCamTransform(studio.coords,studio.rotation,studio.fov)
			end
			Citizen.Wait(0)
		else
			Citizen.Wait(1000)
		end
	end
end)


