local replay = {
	recording = false,
	playing = false,
	editorOpen = false,
	startedAt = 0,
	playStartedAt = 0,
	playFrom = 0,
	time = 0,
	duration = 0,
	editIn = 0,
	editOut = 0,
	playbackRate = 1.0,
	loop = false,
	sampleMs = 100,
	maxMs = 180000,
	radius = 150.0,
	actors = {},
	vehicles = {},
	props = {},
	events = {},
	trackedEntities = {},
	environment = nil,
	ghosts = {
		actors = {},
		vehicles = {},
		props = {}
	},
	hidden = {},
	lastAppliedTime = 0,
	actorRuntime = {},
	eventRuntime = {}
}

local weatherTypes = {
	"CLEAR",
	"EXTRASUNNY",
	"CLOUDS",
	"OVERCAST",
	"RAIN",
	"CLEARING",
	"THUNDER",
	"SMOG",
	"FOGGY",
	"XMAS",
	"SNOWLIGHT",
	"BLIZZARD"
}

local animationPresets = {
	acenar = { dict = "friends@frj@ig_1", name = "wave_a", flag = 49 },
	celular = { dict = "cellphone@", name = "cellphone_text_read_base", flag = 49 },
	prancheta = { dict = "missheistdockssetup1clipboard@base", name = "base", flag = 49 },
	dancar = { dict = "anim@amb@nightclub@dancers@podium_dancers@", name = "hi_dance_facedj_17_v2_male^5", flag = 1 },
	sentar = { dict = "anim@heists@fleeca_bank@ig_7_jetski_owner", name = "owner_idle", flag = 1 }
}

local fxPresets = {
	explosao = 2,
	fogo = 3,
	fumaca = 20
}

local ptfxPresets = {
	faisca = { asset = "core", name = "ent_dst_elec_fire_sp", scale = 1.0 },
	fumaca = { asset = "core", name = "exp_grd_smoke", scale = 1.2 },
	fogo = { asset = "core", name = "ent_sht_flame", scale = 1.0 },
	poeira = { asset = "core", name = "ent_dst_dust", scale = 1.4 }
}

local soundPresets = {
	corte = { name = "SELECT", set = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
	impacto = { name = "ERROR", set = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
	missao = { name = "Mission_Pass_Notify", set = "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS" },
	entrada = { name = "Enter_1st", set = "GTAO_FM_Events_Soundset" }
}

local function replayNotify(kind,message)
    local notifyType = ({ sucesso = "success", negado = "error", aviso = "warning", importante = "inform" })[kind] or "inform"
    if GetResourceState("qbx_core") == "started" then
        exports.qbx_core:Notify(message, notifyType)
    else
        TriggerEvent("ox_lib:notify", { title = "Replay 3D", description = message, type = notifyType })
    end
end

local function currentWeatherName()
	local current = GetPrevWeatherTypeHashName()
	for _,weather in ipairs(weatherTypes) do
		if current == GetHashKey(weather) then
			return weather
		end
	end
	return "CLEAR"
end

local function vecTable(value)
	return { x = value.x, y = value.y, z = value.z }
end

local function vecValue(value)
	return vector3(value.x + 0.0,value.y + 0.0,value.z + 0.0)
end

local function mix(a,b,amount)
	return a + ((b - a) * amount)
end

local function asBool(value)
	return value == true or value == 1
end

local function angleMix(a,b,amount)
	local delta = ((b - a + 180.0) % 360.0) - 180.0
	return a + (delta * amount)
end

local function sendReplayState()
	local actorCount = 0
	local vehicleCount = 0
	local propCount = 0
	local eventCount = #replay.events
	for _ in pairs(replay.actors) do actorCount = actorCount + 1 end
	for _ in pairs(replay.vehicles) do vehicleCount = vehicleCount + 1 end
	for _ in pairs(replay.props) do propCount = propCount + 1 end
	local eventList = {}
	local subjects = {}
	for key,actor in pairs(replay.actors) do
		subjects[#subjects + 1] = { key = "actor:" .. tostring(key), label = actor.name or ("Ator " .. tostring(key)), kind = "ator" }
	end
	for key in pairs(replay.vehicles) do
		subjects[#subjects + 1] = { key = "vehicle:" .. tostring(key), label = "Veiculo " .. tostring(key), kind = "veiculo" }
	end
	for key in pairs(replay.props) do
		subjects[#subjects + 1] = { key = "prop:" .. tostring(key), label = "Objeto " .. tostring(key), kind = "objeto" }
	end
	for index,event in ipairs(replay.events) do
		local label = event.kind
		if event.kind == "anim" then
			label = "anim: " .. (event.preset or event.name or "livre")
		elseif event.kind == "fx" then
			label = "fx: " .. tostring(event.preset)
		elseif event.kind == "ptfx" then
			label = "particula: " .. tostring(event.preset or event.name)
		elseif event.kind == "sound" then
			label = "som: " .. tostring(event.preset)
		end
		eventList[#eventList + 1] = { index = index, t = event.t or 0, label = label }
	end
	TriggerEvent("cinematic_studio:playbackSettings",replay.playbackRate)
	SendNUIMessage({
		action = "replayState",
		recording = replay.recording,
		playing = replay.playing,
		time = replay.time,
		duration = replay.duration,
		editIn = replay.editIn,
		editOut = replay.editOut > 0 and replay.editOut or replay.duration,
		playbackRate = replay.playbackRate,
		loop = replay.loop,
		actorCount = actorCount,
		vehicleCount = vehicleCount,
		propCount = propCount,
		eventCount = eventCount,
		events = eventList,
		subjects = subjects
	})
end

local function requestModel(model)
	if not model or not IsModelInCdimage(model) then return false end
	RequestModel(model)
	local timeout = GetGameTimer() + 3000
	while not HasModelLoaded(model) and GetGameTimer() < timeout do
		Citizen.Wait(0)
	end
	return HasModelLoaded(model)
end

local function requestAnimDict(dict)
	RequestAnimDict(dict)
	local timeout = GetGameTimer() + 3000
	while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
		Citizen.Wait(0)
	end
	return HasAnimDictLoaded(dict)
end

local function performAnimation(ped,presetName,custom)
	local preset = custom and custom.dict and {
		dict = custom.dict,
		name = custom.name,
		flag = custom.flag or 49
	} or animationPresets[presetName]
	if not preset or not DoesEntityExist(ped) or not requestAnimDict(preset.dict) then return end
	TaskPlayAnim(ped,preset.dict,preset.name,8.0,-8.0,-1,preset.flag,0.0,false,false,false)
end

local function requestPtfx(asset)
	RequestNamedPtfxAsset(asset)
	local timeout = GetGameTimer() + 3000
	while not HasNamedPtfxAssetLoaded(asset) and GetGameTimer() < timeout do
		Citizen.Wait(0)
	end
	return HasNamedPtfxAssetLoaded(asset)
end

local function playPtfx(event)
	local preset = ptfxPresets[event.preset]
	local asset = event.asset or (preset and preset.asset)
	local name = event.name or (preset and preset.name)
	local scale = tonumber(event.scale) or (preset and preset.scale) or 1.0
	local coords = event.coords
	if not asset or not name or not coords or not requestPtfx(asset) then return end
	UseParticleFxAssetNextCall(asset)
	StartParticleFxNonLoopedAtCoord(name,coords.x,coords.y,coords.z + 0.05,0.0,0.0,0.0,scale,false,false,false)
end

local function playSoundMarker(event)
	local preset = soundPresets[event.preset]
	local coords = event.coords
	if not preset or not coords then return end
	PlaySoundFromCoord(-1,preset.name,coords.x,coords.y,coords.z,preset.set,false,0,false)
end

local function playFx(event)
	local coords = event and event.coords
	if not coords then return end
	if event.preset == "flash" then
		Citizen.CreateThread(function()
			local untilTime = GetGameTimer() + 250
			while GetGameTimer() < untilTime do
				DrawLightWithRange(coords.x,coords.y,coords.z + 0.4,255,245,220,35.0,18.0)
				Citizen.Wait(0)
			end
		end)
		return
	end
	local explosionType = fxPresets[event.preset]
	if explosionType then
		AddExplosion(coords.x,coords.y,coords.z,explosionType,0.0,true,false,0.0,true)
	end
end

local function captureAppearance(ped)
	local appearance = { components = {}, props = {} }
	for component = 0,11 do
		appearance.components[#appearance.components + 1] = {
			id = component,
			drawable = GetPedDrawableVariation(ped,component),
			texture = GetPedTextureVariation(ped,component),
			palette = GetPedPaletteVariation(ped,component)
		}
	end
	for prop = 0,7 do
		appearance.props[#appearance.props + 1] = {
			id = prop,
			drawable = GetPedPropIndex(ped,prop),
			texture = GetPedPropTextureIndex(ped,prop)
		}
	end
	return appearance
end

local function captureCharacterCustomization(ped)
	if not ped or ped == 0 then return nil end
	
	local shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix, isParent = GetPedHeadBlendData(ped)
	
	local data = {
		fathersID = shapeFirst or 0,
		mothersID = shapeSecond or 0,
		skinColor = skinFirst or 0,
		shapeMix = shapeMix or 0.0,
		eyesColor = GetPedEyeColor(ped) or 0,
		hairModel = GetPedDrawableVariation(ped, 2) or 0,
		firstHairColor = GetPedHairColor(ped) or 0,
		secondHairColor = GetPedHairHighlightColor(ped) or 0
	}
	
	local faceFeatures = {
		[0] = "noseWidth", [1] = "noseHeight", [2] = "noseLength", [3] = "noseBridge",
		[4] = "noseTip", [5] = "noseShift", [6] = "eyebrowsHeight", [7] = "eyebrowsWidth",
		[8] = "cheekboneHeight", [9] = "cheekboneWidth", [10] = "cheeksWidth", [12] = "lips",
		[13] = "jawWidth", [14] = "jawHeight", [15] = "chinLength", [16] = "chinPosition",
		[17] = "chinWidth", [18] = "chinShape", [19] = "neckWidth"
	}
	for feature, key in pairs(faceFeatures) do
		data[key] = GetPedFaceFeature(ped, feature) or 0.0
	end
	
	local overlays = {
		eyebrowsModel = 2,
		beardModel = 1,
		chestModel = 10,
		blushModel = 5,
		lipstickModel = 8,
		blemishesModel = 0,
		ageingModel = 3,
		complexionModel = 6,
		sundamageModel = 7,
		frecklesModel = 9,
		makeupModel = 4
	}
	for key, index in pairs(overlays) do
		local success, overlayValue, colourType, firstColour, secondColour, overlayOpacity = GetPedHeadOverlayData(ped, index)
		if success then
			data[key] = overlayValue
			if key == "eyebrowsModel" then data.eyebrowsColor = firstColour end
			if key == "beardModel" then data.beardColor = firstColour end
			if key == "chestModel" then data.chestColor = firstColour end
			if key == "blushModel" then data.blushColor = firstColour end
			if key == "lipstickModel" then data.lipstickColor = firstColour end
		else
			data[key] = -1
		end
	end
	
	return data
end

local function applyAppearance(ped,appearance)
	if not appearance then return end
	for _,component in ipairs(appearance.components or {}) do
		SetPedComponentVariation(ped,component.id,component.drawable,component.texture,component.palette)
	end
	for _,prop in ipairs(appearance.props or {}) do
		if prop.drawable and prop.drawable >= 0 then
			SetPedPropIndex(ped,prop.id,prop.drawable,prop.texture or 0,true)
		else
			ClearPedProp(ped,prop.id)
		end
	end
end

local function applyCharacterCustomization(ped,data)
	if not data then return end
	SetPedHeadBlendData(ped,data.fathersID or 0,data.mothersID or 0,0,data.skinColor or 0,0,0,tonumber(data.shapeMix) or 0.0,0.0,0.0,false)
	SetPedEyeColor(ped,data.eyesColor or 0)
	local faceFeatures = {
		[0] = "noseWidth", [1] = "noseHeight", [2] = "noseLength", [3] = "noseBridge",
		[4] = "noseTip", [5] = "noseShift", [6] = "eyebrowsHeight", [7] = "eyebrowsWidth",
		[8] = "cheekboneHeight", [9] = "cheekboneWidth", [10] = "cheeksWidth", [12] = "lips",
		[13] = "jawWidth", [14] = "jawHeight", [15] = "chinLength", [16] = "chinPosition",
		[17] = "chinWidth", [18] = "chinShape", [19] = "neckWidth"
	}
	for feature,key in pairs(faceFeatures) do
		SetPedFaceFeature(ped,feature,tonumber(data[key]) or 0.0)
	end
	SetPedComponentVariation(ped,2,data.hairModel or 0,0,0)
	SetPedHairColor(ped,data.firstHairColor or 0,data.secondHairColor or 0)
	local overlays = {
		{ 2, data.eyebrowsModel, 1, data.eyebrowsColor },
		{ 1, data.beardModel, 1, data.beardColor },
		{ 10, data.chestModel, 1, data.chestColor },
		{ 5, data.blushModel, 2, data.blushColor },
		{ 8, data.lipstickModel, 2, data.lipstickColor },
		{ 0, data.blemishesModel, 0, 0 },
		{ 3, data.ageingModel, 0, 0 },
		{ 6, data.complexionModel, 0, 0 },
		{ 7, data.sundamageModel, 0, 0 },
		{ 9, data.frecklesModel, 0, 0 },
		{ 4, data.makeupModel, 0, 0 }
	}
	for _,overlay in ipairs(overlays) do
		SetPedHeadOverlay(ped,overlay[1],overlay[2] or -1,0.99)
		SetPedHeadOverlayColor(ped,overlay[1],overlay[3],overlay[4] or 0,overlay[4] or 0)
	end
end

local function vehicleKey(vehicle,actorKey)
	local netId = NetworkGetNetworkIdFromEntity(vehicle)
	if netId and netId > 0 then return tostring(netId) end
	return "local_" .. actorKey
end

local function trackedKey(entity)
	local netId = NetworkGetNetworkIdFromEntity(entity)
	if netId and netId > 0 then return "net_" .. tostring(netId) end
	return "local_" .. tostring(entity)
end

local function captureVehicleAppearance(vehicle)
	local primary,secondary = GetVehicleColours(vehicle)
	local pearl,wheels = GetVehicleExtraColours(vehicle)
	local mods = {}
	local toggles = {}
	local extras = {}
	SetVehicleModKit(vehicle,0)
	for mod = 0,49 do
		mods[tostring(mod)] = {
			value = GetVehicleMod(vehicle,mod),
			customTyres = GetVehicleModVariation(vehicle,mod)
		}
	end
	for mod = 17,22 do
		toggles[tostring(mod)] = IsToggleModOn(vehicle,mod)
	end
	for extra = 0,20 do
		if DoesExtraExist(vehicle,extra) then
			extras[tostring(extra)] = IsVehicleExtraTurnedOn(vehicle,extra)
		end
	end
	local neonR,neonG,neonB = GetVehicleNeonLightsColour(vehicle)
	local smokeR,smokeG,smokeB = GetVehicleTyreSmokeColor(vehicle)
	local customPrimary = nil
	local customSecondary = nil
	if GetIsVehiclePrimaryColourCustom(vehicle) then
		local r,g,b = GetVehicleCustomPrimaryColour(vehicle)
		customPrimary = { r = r, g = g, b = b }
	end
	if GetIsVehicleSecondaryColourCustom(vehicle) then
		local r,g,b = GetVehicleCustomSecondaryColour(vehicle)
		customSecondary = { r = r, g = g, b = b }
	end
	return {
		plate = GetVehicleNumberPlateText(vehicle),
		plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
		primary = primary,
		secondary = secondary,
		pearl = pearl,
		wheels = wheels,
		livery = GetVehicleLivery(vehicle),
		wheelType = GetVehicleWheelType(vehicle),
		windowTint = GetVehicleWindowTint(vehicle),
		interior = GetVehicleInteriorColour(vehicle),
		dashboard = GetVehicleDashboardColour(vehicle),
		customPrimary = customPrimary,
		customSecondary = customSecondary,
		mods = mods,
		toggles = toggles,
		extras = extras,
		neon = { r = neonR, g = neonG, b = neonB },
		neonEnabled = {
			IsVehicleNeonLightEnabled(vehicle,0),
			IsVehicleNeonLightEnabled(vehicle,1),
			IsVehicleNeonLightEnabled(vehicle,2),
			IsVehicleNeonLightEnabled(vehicle,3)
		},
		smoke = { r = smokeR, g = smokeG, b = smokeB }
	}
end

local function applyVehicleAppearance(vehicle,appearance)
	if not appearance then return end
	SetVehicleModKit(vehicle,0)
	SetVehicleColours(vehicle,appearance.primary or 0,appearance.secondary or 0)
	SetVehicleExtraColours(vehicle,appearance.pearl or 0,appearance.wheels or 0)
	SetVehicleNumberPlateText(vehicle,appearance.plate or "CINEMA")
	SetVehicleNumberPlateTextIndex(vehicle,appearance.plateIndex or 0)
	if appearance.wheelType then SetVehicleWheelType(vehicle,appearance.wheelType) end
	if appearance.windowTint then SetVehicleWindowTint(vehicle,appearance.windowTint) end
	if appearance.interior then SetVehicleInteriorColour(vehicle,appearance.interior) end
	if appearance.dashboard then SetVehicleDashboardColour(vehicle,appearance.dashboard) end
	if appearance.customPrimary then
		SetVehicleCustomPrimaryColour(vehicle,appearance.customPrimary.r,appearance.customPrimary.g,appearance.customPrimary.b)
	end
	if appearance.customSecondary then
		SetVehicleCustomSecondaryColour(vehicle,appearance.customSecondary.r,appearance.customSecondary.g,appearance.customSecondary.b)
	end
	if appearance.livery and appearance.livery >= 0 then
		SetVehicleLivery(vehicle,appearance.livery)
	end
	for mod,data in pairs(appearance.mods or {}) do
		if data.value and data.value >= 0 then
			SetVehicleMod(vehicle,tonumber(mod),data.value,data.customTyres == true)
		end
	end
	for mod,enabled in pairs(appearance.toggles or {}) do
		ToggleVehicleMod(vehicle,tonumber(mod),enabled == true)
	end
	for extra,enabled in pairs(appearance.extras or {}) do
		SetVehicleExtra(vehicle,tonumber(extra),enabled and 0 or 1)
	end
	if appearance.neon then
		SetVehicleNeonLightsColour(vehicle,appearance.neon.r or 255,appearance.neon.g or 255,appearance.neon.b or 255)
	end
	for side,enabled in ipairs(appearance.neonEnabled or {}) do
		SetVehicleNeonLightEnabled(vehicle,side - 1,enabled == true)
	end
	if appearance.smoke then
		SetVehicleTyreSmokeColor(vehicle,appearance.smoke.r or 255,appearance.smoke.g or 255,appearance.smoke.b or 255)
	end
end

local function captureVehicleState(vehicle,time)
	local _,lights,highbeams = GetVehicleLightsState(vehicle)
	local engine = GetIsVehicleEngineRunning(vehicle)
	local siren = IsVehicleSirenOn(vehicle)
	local doors = {}
	local damagedDoors = {}
	local tyres = {}
	local windows = {}
	for door = 0,5 do
		doors[#doors + 1] = GetVehicleDoorAngleRatio(vehicle,door)
		damagedDoors[#damagedDoors + 1] = IsVehicleDoorDamaged(vehicle,door)
	end
	for tyre = 0,7 do
		tyres[#tyres + 1] = IsVehicleTyreBurst(vehicle,tyre,false)
	end
	for window = 0,7 do
		windows[#windows + 1] = not IsVehicleWindowIntact(vehicle,window)
	end
	return {
		t = time,
		coords = vecTable(GetEntityCoords(vehicle)),
		rotation = vecTable(GetEntityRotation(vehicle,2)),
		engine = asBool(engine),
		siren = asBool(siren),
		lights = asBool(lights),
		highbeams = asBool(highbeams),
		engineHealth = GetVehicleEngineHealth(vehicle),
		bodyHealth = GetVehicleBodyHealth(vehicle),
		tankHealth = GetVehiclePetrolTankHealth(vehicle),
		dirt = GetVehicleDirtLevel(vehicle),
		doors = doors,
		damagedDoors = damagedDoors,
		tyres = tyres,
		windows = windows,
		driveable = IsVehicleDriveable(vehicle,false)
	}
end

local function captureMovementState(ped)
	if IsPedSprinting(ped) then return "sprint" end
	if IsPedRunning(ped) then return "run" end
	if IsPedWalking(ped) then return "walk" end
	if IsPedRagdoll(ped) then return "ragdoll" end
	return "idle"
end

local function clearGhosts()
	for key,entity in pairs(replay.ghosts.actors) do
		if DoesEntityExist(entity) then DeletePed(entity) end
		replay.ghosts.actors[key] = nil
	end
	for key,entity in pairs(replay.ghosts.vehicles) do
		if DoesEntityExist(entity) then DeleteVehicle(entity) end
		replay.ghosts.vehicles[key] = nil
	end
	for key,entity in pairs(replay.ghosts.props) do
		if DoesEntityExist(entity) then DeleteObject(entity) end
		replay.ghosts.props[key] = nil
	end
	for _,entity in pairs(replay.hidden) do
		if DoesEntityExist(entity) then SetEntityVisible(entity,true,false) end
	end
	replay.hidden = {}
end

local function resetReplay()
	replay.playing = false
	replay.time = 0
	replay.duration = 0
	replay.editIn = 0
	replay.editOut = 0
	replay.playbackRate = 1.0
	replay.loop = false
	replay.actors = {}
	replay.vehicles = {}
	replay.props = {}
	replay.events = {}
	replay.environment = nil
	replay.lastAppliedTime = 0
	replay.actorRuntime = {}
	replay.eventRuntime = {}
	clearGhosts()
	sendReplayState()
end

local function recordActor(player,time)
	local ped = GetPlayerPed(player)
	if ped == 0 or not DoesEntityExist(ped) then return end

	local directorCoords = GetEntityCoords(PlayerPedId())
	local coords = GetEntityCoords(ped)
	if #(coords - directorCoords) > replay.radius then return end

	local key = tostring(GetPlayerServerId(player))
	local actor = replay.actors[key]
	if not actor then
		actor = {
			name = GetPlayerName(player) or ("Ator " .. key),
			model = GetEntityModel(ped),
			appearance = captureAppearance(ped),
			character = captureCharacterCustomization(ped),
			track = {},
			shots = {},
			lastShot = -1000
		}
		replay.actors[key] = actor
	end

	local frame = {
		t = time,
		coords = vecTable(coords),
		rotation = vecTable(GetEntityRotation(ped,2)),
		vehicle = nil,
		seat = nil,
		weapon = GetSelectedPedWeapon(ped),
		health = GetEntityHealth(ped),
		armour = GetPedArmour(ped),
		dead = IsEntityDead(ped),
		movement = captureMovementState(ped)
	}

	if IsPedShooting(ped) and time - actor.lastShot > 120 then
		actor.shots[#actor.shots + 1] = {
			t = time,
			coords = vecTable(coords),
			rotation = vecTable(GetEntityRotation(ped,2)),
			weapon = frame.weapon
		}
		actor.lastShot = time
	end

	if IsPedInAnyVehicle(ped,false) then
		local vehicle = GetVehiclePedIsIn(ped,false)
		local keyVehicle = vehicleKey(vehicle,key)
		frame.vehicle = keyVehicle
		for seat = -1,GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
			if GetPedInVehicleSeat(vehicle,seat) == ped then
				frame.seat = seat
				break
			end
		end
		if not replay.vehicles[keyVehicle] then
			replay.vehicles[keyVehicle] = {
				model = GetEntityModel(vehicle),
				netId = NetworkGetNetworkIdFromEntity(vehicle),
				appearance = captureVehicleAppearance(vehicle),
				track = {}
			}
		end
		local vehicleTrack = replay.vehicles[keyVehicle].track
		if #vehicleTrack == 0 or vehicleTrack[#vehicleTrack].t ~= time then
			vehicleTrack[#vehicleTrack + 1] = captureVehicleState(vehicle,time)
		end
	end

	actor.track[#actor.track + 1] = frame
end

local function captureTrackedEntities(time)
	for key,item in pairs(replay.trackedEntities) do
		local entity = item.entity
		if not DoesEntityExist(entity) then
			replay.trackedEntities[key] = nil
		elseif item.kind == "object" then
			if not replay.props[key] then
				replay.props[key] = {
					model = GetEntityModel(entity),
					entity = entity,
					track = {}
				}
			end
			replay.props[key].track[#replay.props[key].track + 1] = {
				t = time,
				coords = vecTable(GetEntityCoords(entity)),
				rotation = vecTable(GetEntityRotation(entity,2))
			}
		elseif item.kind == "vehicle" then
			local vehicleKeyValue = "scene_" .. key
			for knownKey,knownVehicle in pairs(replay.vehicles) do
				if knownVehicle.netId and knownVehicle.netId == NetworkGetNetworkIdFromEntity(entity) then
					vehicleKeyValue = knownKey
					break
				end
			end
			if not replay.vehicles[vehicleKeyValue] then
				replay.vehicles[vehicleKeyValue] = {
					model = GetEntityModel(entity),
					netId = NetworkGetNetworkIdFromEntity(entity),
					appearance = captureVehicleAppearance(entity),
					track = {}
				}
			end
			local track = replay.vehicles[vehicleKeyValue].track
			if #track == 0 or track[#track].t ~= time then
				track[#track + 1] = captureVehicleState(entity,time)
			end
		elseif item.kind == "ped" then
			local actorKey = "scene_" .. key
			local actor = replay.actors[actorKey]
			if not actor then
				actor = {
					name = "Figurante",
					model = GetEntityModel(entity),
					appearance = captureAppearance(entity),
					character = captureCharacterCustomization(entity),
					track = {},
					shots = {},
					lastShot = -1000
				}
				replay.actors[actorKey] = actor
			end
			local frame = {
				t = time,
				coords = vecTable(GetEntityCoords(entity)),
				rotation = vecTable(GetEntityRotation(entity,2)),
				vehicle = nil,
				seat = nil,
				weapon = GetSelectedPedWeapon(entity),
				health = GetEntityHealth(entity),
				armour = GetPedArmour(entity),
				dead = IsEntityDead(entity),
				movement = captureMovementState(entity)
			}
			actor.track[#actor.track + 1] = frame
			if IsPedShooting(entity) and time - actor.lastShot > 120 then
				actor.shots[#actor.shots + 1] = {
					t = time,
					coords = vecTable(GetEntityCoords(entity)),
					rotation = vecTable(GetEntityRotation(entity,2)),
					weapon = frame.weapon
				}
				actor.lastShot = time
			end
		end
	end
end

local function captureSample(time)
	for _,player in ipairs(GetActivePlayers()) do
		recordActor(player,time)
	end
	captureTrackedEntities(time)
end

local function startRecording()
	if replay.recording then return end
	if replay.editorOpen then
		replayNotify("aviso","Saia do Studio para atuar e iniciar uma gravacao.")
		return
	end
	resetReplay()
	replay.environment = {
		hour = GetClockHours(),
		minute = GetClockMinutes(),
		second = GetClockSeconds(),
		weather = currentWeatherName()
	}
	replay.recording = true
	replay.startedAt = GetGameTimer()
	replayNotify("sucesso","Replay 3D gravando. Atue normalmente; use /take stop ao terminar.")
	sendReplayState()

	Citizen.CreateThread(function()
		while replay.recording do
			local time = GetGameTimer() - replay.startedAt
			replay.duration = time
			replay.editOut = time
			replay.time = time
			captureSample(time)
			if time >= replay.maxMs then
				replay.recording = false
				replayNotify("aviso","Replay encerrado no limite de 3 minutos.")
			end
			sendReplayState()
			Citizen.Wait(replay.sampleMs)
		end
	end)
end

local function stopRecording()
	if not replay.recording then
		replayNotify("aviso","Nenhuma cena esta sendo gravada.")
		return
	end
	replay.recording = false
	replay.time = 0
	replay.editIn = 0
	replay.editOut = replay.duration
	TriggerServerEvent("cinematic_studio:requestCharacterLooks")
	sendReplayState()
	replayNotify("sucesso","Cena salva na memoria. Abra /studio para montar cameras em 3D.")
end

local function findFrames(track,time)
	if not track or #track == 0 then return nil,nil,0.0 end
	if time <= track[1].t then return track[1],track[1],0.0 end
	if time >= track[#track].t then return track[#track],track[#track],0.0 end
	local low,high = 1,#track
	while low <= high do
		local middle = math.floor((low + high) / 2)
		if track[middle].t <= time then
			low = middle + 1
		else
			high = middle - 1
		end
	end
	local first = track[math.max(1,high)]
	local second = track[math.min(#track,high + 1)]
	local interval = math.max(1,second.t - first.t)
	return first,second,(time - first.t) / interval
end

local function setTransform(entity,first,second,amount)
	if not first or not DoesEntityExist(entity) then return end
	local startCoords = vecValue(first.coords)
	local endCoords = vecValue(second.coords)
	local startRot = vecValue(first.rotation)
	local endRot = vecValue(second.rotation)
	SetEntityCoordsNoOffset(entity,mix(startCoords.x,endCoords.x,amount),mix(startCoords.y,endCoords.y,amount),mix(startCoords.z,endCoords.z,amount),false,false,false)
	SetEntityRotation(entity,angleMix(startRot.x,endRot.x,amount),angleMix(startRot.y,endRot.y,amount),angleMix(startRot.z,endRot.z,amount),2,true)
end

local function applyVehicleState(vehicle,first,second,amount)
	if not first or not DoesEntityExist(vehicle) then return end
	SetVehicleEngineOn(vehicle,first.engine,true,true)
	SetVehicleSiren(vehicle,first.siren == true)
	SetVehicleLights(vehicle,first.lights and 2 or 1)
	SetVehicleFullbeam(vehicle,first.highbeams == true)
	SetVehicleEngineHealth(vehicle,mix(first.engineHealth or 1000.0,second.engineHealth or first.engineHealth or 1000.0,amount))
	SetVehicleBodyHealth(vehicle,mix(first.bodyHealth or 1000.0,second.bodyHealth or first.bodyHealth or 1000.0,amount))
	SetVehiclePetrolTankHealth(vehicle,mix(first.tankHealth or 1000.0,second.tankHealth or first.tankHealth or 1000.0,amount))
	SetVehicleDirtLevel(vehicle,mix(first.dirt or 0.0,second.dirt or first.dirt or 0.0,amount))
	SetVehicleUndriveable(vehicle,first.driveable == false)
	for door = 0,5 do
		local broken = (first.damagedDoors or {})[door + 1] == true
		local open = ((first.doors or {})[door + 1] or 0.0) > 0.05
		if broken then
			SetVehicleDoorBroken(vehicle,door,true)
		elseif open then
			SetVehicleDoorOpen(vehicle,door,false,false)
		else
			SetVehicleDoorShut(vehicle,door,false)
		end
	end
	for tyre = 0,7 do
		if (first.tyres or {})[tyre + 1] == true then
			SetVehicleTyreBurst(vehicle,tyre,true,1000.0)
		end
	end
	for window = 0,7 do
		if (first.windows or {})[window + 1] == true then
			SmashVehicleWindow(vehicle,window)
		end
	end
end

local function applyActorState(actor,ped,first)
	if not first or not DoesEntityExist(ped) then return end
	if first.weapon and first.weapon ~= GetHashKey("WEAPON_UNARMED") then
		if not HasPedGotWeapon(ped,first.weapon,false) then
			GiveWeaponToPed(ped,first.weapon,999,false,true)
		end
		SetCurrentPedWeapon(ped,first.weapon,true)
	else
		SetCurrentPedWeapon(ped,GetHashKey("WEAPON_UNARMED"),true)
	end
	SetEntityHealth(ped,math.max(100,first.health or 200))
	SetPedArmour(ped,first.armour or 0)
	if first.dead then
		SetPedToRagdoll(ped,250,250,0,false,false,false)
	end
end

local function applyActorMotion(key,ped,first,second,time)
	if not first or first.vehicle or not DoesEntityExist(ped) then return end
	local runtime = replay.actorRuntime[key] or { state = nil, taskedAt = -1000 }
	replay.actorRuntime[key] = runtime
	local moving = first.movement == "walk" or first.movement == "run" or first.movement == "sprint"

	if replay.playing and moving and not first.dead then
		FreezeEntityPosition(ped,false)
		if runtime.state ~= first.movement or time - runtime.taskedAt > 350 then
			local target = vecValue(second.coords)
			local speed = first.movement == "sprint" and 5.5 or (first.movement == "run" and 3.2 or 1.25)
			TaskGoStraightToCoord(ped,target.x,target.y,target.z,speed,500,second.rotation.z or 0.0,0.1)
			runtime.state = first.movement
			runtime.taskedAt = time
		end
	else
		if runtime.state ~= "still" then
			ClearPedTasks(ped)
			runtime.state = "still"
		end
		FreezeEntityPosition(ped,true)
	end
end

local function fireRecordedShots(actor,ped,previousTime,time)
	for _,shot in ipairs(actor.shots or {}) do
		if shot.t > previousTime and shot.t <= time then
			local source = GetPedBoneCoords(ped,57005,0.0,0.0,0.0)
			local rotation = vecValue(shot.rotation)
			local heading = math.rad(rotation.z)
			local pitch = math.rad(rotation.x)
			local direction = vector3(-math.sin(heading) * math.abs(math.cos(pitch)),math.cos(heading) * math.abs(math.cos(pitch)),math.sin(pitch))
			local target = source + (direction * 60.0)
			ShootSingleBulletBetweenCoords(source.x,source.y,source.z,target.x,target.y,target.z,0,true,shot.weapon or GetHashKey("WEAPON_PISTOL"),ped,true,false,100.0)
		end
	end
end

local function applyRecordedEvent(event)
	if event.kind == "fx" then
		playFx(event)
	elseif event.kind == "ptfx" then
		playPtfx(event)
	elseif event.kind == "sound" then
		playSoundMarker(event)
	elseif event.kind == "anim" then
		local ped = replay.ghosts.actors[tostring(event.actor)]
		if not ped or not DoesEntityExist(ped) then return end
		if event.action == "stop" then
			ClearPedTasks(ped)
			replay.actorRuntime[tostring(event.actor)] = nil
		else
			performAnimation(ped,event.preset,event)
		end
	end
end

local function restoreRecordedAnimations(time)
	local current = {}
	for _,event in ipairs(replay.events or {}) do
		if event.t <= time and event.kind == "anim" then
			current[tostring(event.actor)] = event
		end
	end
	for key,ped in pairs(replay.ghosts.actors) do
		if DoesEntityExist(ped) then
			ClearPedTasks(ped)
			local event = current[key]
			if event and event.action ~= "stop" then
				performAnimation(ped,event.preset,event)
			end
		end
	end
end

local function playRecordedEvents(previousTime,time)
	if time < previousTime then
		restoreRecordedAnimations(time)
		return
	end
	for _,event in ipairs(replay.events or {}) do
		if event.t > previousTime and event.t <= time then
			applyRecordedEvent(event)
		end
	end
end

local function buildGhosts()
	clearGhosts()
	for key,vehicle in pairs(replay.vehicles) do
		local first = vehicle.track[1]
		if first and requestModel(vehicle.model) then
			local coords = vecValue(first.coords)
			local entity = CreateVehicle(vehicle.model,coords.x,coords.y,coords.z,0.0,false,false)
			applyVehicleAppearance(entity,vehicle.appearance)
			SetEntityCollision(entity,false,false)
			SetEntityInvincible(entity,true)
			FreezeEntityPosition(entity,true)
			replay.ghosts.vehicles[key] = entity
			SetModelAsNoLongerNeeded(vehicle.model)
		end
	end
	for key,prop in pairs(replay.props) do
		local first = prop.track[1]
		if first and requestModel(prop.model) then
			local coords = vecValue(first.coords)
			local entity = CreateObjectNoOffset(prop.model,coords.x,coords.y,coords.z,false,false,false)
			SetEntityCollision(entity,false,false)
			FreezeEntityPosition(entity,true)
			replay.ghosts.props[key] = entity
			SetModelAsNoLongerNeeded(prop.model)
			if prop.entity and DoesEntityExist(prop.entity) then
				replay.hidden["prop_" .. key] = prop.entity
				SetEntityVisible(prop.entity,false,false)
			end
		end
	end
	for key,actor in pairs(replay.actors) do
		local first = actor.track[1]
		if first and requestModel(actor.model) then
			local coords = vecValue(first.coords)
			local entity = CreatePed(4,actor.model,coords.x,coords.y,coords.z,0.0,false,false)
			applyAppearance(entity,actor.appearance)
			applyCharacterCustomization(entity,actor.character)
			SetEntityCollision(entity,false,false)
			SetEntityInvincible(entity,true)
			FreezeEntityPosition(entity,true)
			SetBlockingOfNonTemporaryEvents(entity,true)
			replay.ghosts.actors[key] = entity
			SetModelAsNoLongerNeeded(actor.model)
		end
	end
	restoreRecordedAnimations(replay.time)

	local localServerId = tostring(GetPlayerServerId(PlayerId()))
	for _,player in ipairs(GetActivePlayers()) do
		local key = tostring(GetPlayerServerId(player))
		if key ~= localServerId and replay.actors[key] then
			local ped = GetPlayerPed(player)
			if ped ~= 0 and DoesEntityExist(ped) then
				replay.hidden[key] = ped
				SetEntityVisible(ped,false,false)
			end
		end
	end
	for key,item in pairs(replay.trackedEntities) do
		if item.kind == "ped" and DoesEntityExist(item.entity) then
			replay.hidden["scene_ped_" .. key] = item.entity
			SetEntityVisible(item.entity,false,false)
		end
	end
	for key,vehicle in pairs(replay.vehicles) do
		if vehicle.netId and NetworkDoesEntityExistWithNetworkId(vehicle.netId) then
			local original = NetToVeh(vehicle.netId)
			if original and original ~= 0 and DoesEntityExist(original) then
				replay.hidden["vehicle_" .. key] = original
				SetEntityVisible(original,false,false)
			end
		end
	end
end

local function applyPlayback(time)
	for key,vehicle in pairs(replay.vehicles) do
		local entity = replay.ghosts.vehicles[key]
		local first,second,amount = findFrames(vehicle.track,time)
		setTransform(entity,first,second,amount)
		applyVehicleState(entity,first,second,amount)
	end
	for key,prop in pairs(replay.props) do
		local entity = replay.ghosts.props[key]
		local first,second,amount = findFrames(prop.track,time)
		setTransform(entity,first,second,amount)
	end
	for key,actor in pairs(replay.actors) do
		local entity = replay.ghosts.actors[key]
		local first,second,amount = findFrames(actor.track,time)
		if entity and first then
			if first.vehicle and replay.ghosts.vehicles[first.vehicle] then
				local vehicle = replay.ghosts.vehicles[first.vehicle]
				if not IsPedInVehicle(entity,vehicle,false) then
					FreezeEntityPosition(entity,false)
					SetPedIntoVehicle(entity,vehicle,first.seat or -1)
				end
			else
				if IsPedInAnyVehicle(entity,false) then
					ClearPedTasksImmediately(entity)
				end
				setTransform(entity,first,second,amount)
			end
			applyActorState(actor,entity,first)
			applyActorMotion(key,entity,first,second,time)
			fireRecordedShots(actor,entity,replay.lastAppliedTime,time)
		end
	end
	playRecordedEvents(replay.lastAppliedTime,time)
	if replay.environment then
		NetworkOverrideClockTime(replay.environment.hour,replay.environment.minute,replay.environment.second)
		SetWeatherTypeNowPersist(replay.environment.weather or "CLEAR")
	end
	replay.lastAppliedTime = time
end

local function aimCoords()
	local origin = GetGameplayCamCoord()
	local rotation = GetGameplayCamRot(2)
	local heading = math.rad(rotation.z)
	local pitch = math.rad(rotation.x)
	local direction = vector3(-math.sin(heading) * math.abs(math.cos(pitch)),math.cos(heading) * math.abs(math.cos(pitch)),math.sin(pitch))
	local destination = origin + (direction * 100.0)
	local ray = StartExpensiveSynchronousShapeTestLosProbe(origin.x,origin.y,origin.z,destination.x,destination.y,destination.z,-1,PlayerPedId(),7)
	local _,hit,endCoords = GetShapeTestResult(ray)
	if hit == 1 then return vecTable(endCoords) end
	return vecTable(GetEntityCoords(PlayerPedId()) + (GetEntityForwardVector(PlayerPedId()) * 3.0))
end

local function captureSceneEvent(event)
	if not replay.recording or type(event) ~= "table" then return end
	event.t = GetGameTimer() - replay.startedAt
	replay.events[#replay.events + 1] = event
	sendReplayState()
end

local function startPlayback(fromBeginning)
	if replay.duration <= 0 then
		replayNotify("aviso","Grave uma cena primeiro com /take start.")
		return
	end
	local sequenceStart = math.max(0,math.min(replay.duration,replay.editIn or 0))
	local sequenceEnd = math.min(replay.duration,math.max(sequenceStart + 100,math.min(replay.duration,replay.editOut > 0 and replay.editOut or replay.duration)))
	if sequenceEnd <= sequenceStart then
		sequenceStart = 0
		sequenceEnd = replay.duration
	end
	if fromBeginning or replay.time < sequenceStart or replay.time >= sequenceEnd then
		replay.time = sequenceStart
		buildGhosts()
	elseif next(replay.ghosts.actors) == nil then
		buildGhosts()
	end
	replay.lastAppliedTime = replay.time - 1
	replay.playFrom = replay.time
	replay.playStartedAt = GetGameTimer()
	replay.actorRuntime = {}
	replay.playing = true
	sendReplayState()
end

local function stopPlayback()
	replay.playing = false
	sendReplayState()
end

AddEventHandler("cinematic_studio:trackEntity",function(kind,entity)
	if entity and DoesEntityExist(entity) and (kind == "object" or kind == "vehicle" or kind == "ped") then
		replay.trackedEntities[trackedKey(entity)] = { kind = kind, entity = entity }
	end
end)

RegisterNetEvent("cinematic_studio:sceneEvent")
AddEventHandler("cinematic_studio:sceneEvent",function(event)
	if type(event) ~= "table" then return end
	if event.kind == "anim" and tostring(event.actor) == tostring(GetPlayerServerId(PlayerId())) then
		if event.action == "stop" then
			ClearPedTasks(PlayerPedId())
		else
			performAnimation(PlayerPedId(),event.preset,event)
		end
	elseif event.kind == "fx" then
		playFx(event)
	elseif event.kind == "ptfx" then
		playPtfx(event)
	elseif event.kind == "sound" then
		playSoundMarker(event)
	end
	captureSceneEvent(event)
end)

RegisterNetEvent("cinematic_studio:placeFx")
AddEventHandler("cinematic_studio:placeFx",function(preset)
	TriggerServerEvent("cinematic_studio:submitFx",preset,aimCoords())
end)

RegisterNetEvent("cinematic_studio:placeMarker")
AddEventHandler("cinematic_studio:placeMarker",function(kind,preset,metadata)
	TriggerServerEvent("cinematic_studio:submitMarker",kind,preset,metadata or {},aimCoords())
end)

local function ghostSubject(subjectKey)
	if type(subjectKey) ~= "string" then return nil,nil end
	local kind,key = subjectKey:match("^(%a+):(.*)$")
	if kind == "actor" then
		return replay.ghosts.actors[key],replay.actors[key] and (replay.actors[key].name or "Ator")
	elseif kind == "vehicle" then
		return replay.ghosts.vehicles[key],"Veiculo"
	elseif kind == "prop" then
		return replay.ghosts.props[key],"Objeto"
	end
	return nil,nil
end

AddEventHandler("cinematic_studio:resolveCameraTarget",function(subjectKey)
	local entity,label = ghostSubject(subjectKey)
	TriggerEvent("cinematic_studio:cameraTarget",subjectKey,entity,label)
end)

RegisterNUICallback("focusSubject",function(data,callback)
	if replay.duration > 0 and next(replay.ghosts.actors) == nil and next(replay.ghosts.vehicles) == nil then
		buildGhosts()
		applyPlayback(replay.time)
	end
	local entity,label = ghostSubject(data.key)
	TriggerEvent("cinematic_studio:cameraTarget",data.key,entity,label)
	callback({ ok = entity ~= nil })
end)

RegisterNUICallback("clearSubject",function(_,callback)
	TriggerEvent("cinematic_studio:cameraTarget",nil,nil,nil)
	callback({ ok = true })
end)

RegisterNetEvent("cinematic_studio:characterLooks")
AddEventHandler("cinematic_studio:characterLooks",function(looks)
	for actorKey,character in pairs(looks or {}) do
		if replay.actors[tostring(actorKey)] then
			replay.actors[tostring(actorKey)].character = character
		end
	end
	replayNotify("sucesso","Aparencia detalhada dos atores vinculada ao Replay 3D.")
end)

RegisterNetEvent("cinematic_studio:takeAction")
AddEventHandler("cinematic_studio:takeAction",function(action)
	if action == "start" then
		startRecording()
	elseif action == "stop" then
		stopRecording()
	elseif action == "clear" then
		resetReplay()
		replayNotify("importante","Cena gravada apagada.")
	end
end)

AddEventHandler("cinematic_studio:editorOpened",function()
	replay.editorOpen = true
	if replay.duration > 0 then
		buildGhosts()
		replay.lastAppliedTime = replay.time
		applyPlayback(replay.time)
	end
	sendReplayState()
end)

AddEventHandler("cinematic_studio:editorClosed",function()
	replay.editorOpen = false
	stopPlayback()
	clearGhosts()
	NetworkClearClockTimeOverride()
	ClearWeatherTypePersist()
	ClearOverrideWeather()
end)

AddEventHandler("cinematic_studio:requestReplayState",sendReplayState)
AddEventHandler("cinematic_studio:cameraSequenceStarted",function()
	startPlayback(true)
end)
AddEventHandler("cinematic_studio:cameraSequenceStopped",stopPlayback)

RegisterNUICallback("replayPlay",function(_,callback)
	startPlayback(false)
	callback({ ok = true })
end)

RegisterNUICallback("replayRestart",function(_,callback)
	startPlayback(true)
	callback({ ok = true })
end)

RegisterNUICallback("replayPause",function(_,callback)
	stopPlayback()
	callback({ ok = true })
end)

RegisterNUICallback("replaySetIn",function(_,callback)
	local limit = replay.editOut > 0 and replay.editOut or replay.duration
	replay.editIn = math.max(0,math.min(replay.time,math.max(0,limit - 100)))
	sendReplayState()
	callback({ ok = true })
end)

RegisterNUICallback("replaySetOut",function(_,callback)
	replay.editOut = math.max(replay.editIn + 100,math.min(replay.duration,replay.time))
	sendReplayState()
	callback({ ok = true })
end)

RegisterNUICallback("replayResetRange",function(_,callback)
	replay.editIn = 0
	replay.editOut = replay.duration
	sendReplayState()
	callback({ ok = true })
end)

RegisterNUICallback("replayPlayback",function(data,callback)
	replay.playbackRate = math.max(0.1,math.min(2.0,tonumber(data.rate) or 1.0))
	replay.loop = data.loop == true
	if replay.playing then
		replay.playFrom = replay.time
		replay.playStartedAt = GetGameTimer()
	end
	sendReplayState()
	callback({ ok = true })
end)

RegisterNUICallback("replaySeek",function(data,callback)
	replay.playing = false
	replay.time = math.max(0,math.min(replay.duration,tonumber(data.time) or 0))
	buildGhosts()
	replay.lastAppliedTime = replay.time
	applyPlayback(replay.time)
	restoreRecordedAnimations(replay.time)
	sendReplayState()
	callback({ ok = true })
end)

RegisterNUICallback("replayDeleteEvent",function(data,callback)
	local index = tonumber(data.index)
	if index and replay.events[index] then
		table.remove(replay.events,index)
		if replay.editorOpen and replay.duration > 0 then
			buildGhosts()
			replay.lastAppliedTime = replay.time
			applyPlayback(replay.time)
			restoreRecordedAnimations(replay.time)
		end
		sendReplayState()
	end
	callback({ ok = true })
end)

RegisterNUICallback("replayClear",function(_,callback)
	resetReplay()
	callback({ ok = true })
end)

RegisterNUICallback("replaySave",function(_,callback)
	if replay.duration <= 0 then
		replayNotify("aviso","Nenhuma cena foi gravada para salvar.")
	else
		local payload = json.encode({
			duration = replay.duration,
			editIn = replay.editIn,
			editOut = replay.editOut,
			playbackRate = replay.playbackRate,
			loop = replay.loop,
			environment = replay.environment,
			actors = replay.actors,
			vehicles = replay.vehicles,
			props = replay.props,
			events = replay.events
		})
		TriggerLatentServerEvent("cinematic_studio:saveTake",25000,payload)
	end
	callback({ ok = true })
end)

RegisterNUICallback("replayLoad",function(_,callback)
	TriggerServerEvent("cinematic_studio:loadTake")
	callback({ ok = true })
end)

RegisterNetEvent("cinematic_studio:takeLoaded")
AddEventHandler("cinematic_studio:takeLoaded",function(encodedTake)
	local take = json.decode(encodedTake or "")
	if not take then
		replayNotify("negado","Falha ao carregar a cena salva.")
		return
	end
	clearGhosts()
	replay.playing = false
	replay.time = 0
	replay.duration = take.duration or 0
	replay.editIn = take.editIn or 0
	replay.editOut = take.editOut or replay.duration
	replay.playbackRate = take.playbackRate or 1.0
	replay.loop = take.loop == true
	replay.environment = take.environment
	replay.actors = take.actors or {}
	replay.vehicles = take.vehicles or {}
	replay.props = take.props or {}
	replay.events = take.events or {}
	for _,prop in pairs(replay.props) do
		prop.entity = nil
	end
	replay.actorRuntime = {}
	if replay.editorOpen and replay.duration > 0 then
		buildGhosts()
		replay.lastAppliedTime = 0
		applyPlayback(0)
	end
	sendReplayState()
	replayNotify("sucesso","Cena 3D carregada.")
end)

Citizen.CreateThread(function()
	while true do
		if replay.playing then
			local sequenceEnd = replay.editOut > 0 and replay.editOut or replay.duration
			replay.time = math.min(sequenceEnd,replay.playFrom + ((GetGameTimer() - replay.playStartedAt) * replay.playbackRate))
			applyPlayback(replay.time)
			if replay.time >= sequenceEnd then
				if replay.loop then
					replay.time = replay.editIn or 0
					buildGhosts()
					replay.lastAppliedTime = replay.time - 1
					replay.playFrom = replay.time
					replay.playStartedAt = GetGameTimer()
				else
					replay.playing = false
				end
			end
			sendReplayState()
			Citizen.Wait(0)
		else
			if replay.recording then
				DrawRect(0.94,0.06,0.095,0.038,0,0,0,165)
				SetTextFont(4)
				SetTextScale(0.32,0.32)
				SetTextColour(224,55,50,255)
				SetTextEntry("STRING")
				AddTextComponentString("REC 3D")
				DrawText(0.902,0.049)
			end
			Citizen.Wait(150)
		end
	end
end)

AddEventHandler("onResourceStop",function(resource)
	if resource == GetCurrentResourceName() then
		clearGhosts()
	end
end)


