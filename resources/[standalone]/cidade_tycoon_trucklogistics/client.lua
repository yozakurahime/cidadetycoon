-- Qbox client APIs are accessed through exports when needed.
local truck,truck_blip,trailer,trailer_blip,rentTruck,route_blip
local openFuelPageOnLoad = false
menuactive = false
empresaAtual = nil
loading = false
cooldown = nil

local function angleDifference(angle1, angle2)
	local diff = (angle1 - angle2 + 180.0) % 360.0 - 180.0
	return math.abs(diff)
end

local function notify(message, notifyType)
	exports.qbx_core:Notify(message, notifyType == 'primary' and 'inform' or (notifyType or 'inform'))
end
CreateThread(function()
	Wait(1000)
	for _, blip in pairs(Config.blips or {}) do
		addBlip(blip[1], blip[2], blip[3], blip[4], blip[5], blip[6], blip[7], blip[8])
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- LOCAIS
-----------------------------------------------------------------------------------------------------------------------------------------	
local spawnedPeds = {}
local abertoViaTablet = false

CreateThread(function()
    if Config.spawnNPCs then
        for k, v in pairs(Config.empresas) do
            local point = lib.points.new({
                coords = vector3(v.coordenada[1], v.coordenada[2], v.coordenada[3]),
                distance = 60.0
            })

            function point:onEnter()
                if not spawnedPeds[k] then
                    local model = GetHashKey(v.ped)
                    RequestModel(model)
                    while not HasModelLoaded(model) do Wait(10) end

                    local ped = CreatePed(4, model, v.coordenada[1], v.coordenada[2], v.coordenada[3] - 1.0, v.heading, false, true)
                    SetEntityAsMissionEntity(ped, true, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    SetEntityInvincible(ped, true)
                    FreezeEntityPosition(ped, true)
                    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)

                    spawnedPeds[k] = ped

                    -- Adiciona Blip vinculado ao NPC (Segue o NPC se movido)
                    local blip = AddBlipForEntity(ped)
                    SetBlipSprite(blip, 478)
                    SetBlipColour(blip, 4)
                    SetBlipScale(blip, 0.7)
                    SetBlipAsShortRange(blip, true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString(v.nome or "Transportadora")
                    EndTextCommandSetBlipName(blip)

                    -- Interação via ox_target (Terceiro Olho)
                    exports.ox_target:addLocalEntity(ped, {
                        {
                            name = 'open_trucker_menu_' .. k,
                            label = 'Gerenciar Transportadora',
                            icon = 'fa-solid fa-truck-ramp-box',
                            distance = 2.5,
                            onSelect = function()
                                if not menuactive then
                                    TriggerEvent('cidade_tycoon_tablet:client:openTablet', 'trucker')
                                    TriggerEvent('cidade_tycoon_trucklogistics:openViaTablet', k)
                                end
                            end
                        },
                        {
                            name = 'open_trucker_fuel_' .. k,
                            label = 'Gerenciar Depósito de Combustível',
                            icon = 'fa-solid fa-gas-pump',
                            distance = 2.5,
                            onSelect = function()
                                if not menuactive then
                                    empresaAtual = k
                                    openFuelPageOnLoad = true
                                    TriggerEvent('cidade_tycoon_tablet:client:openTablet', 'trucker')
                                    TriggerEvent('cidade_tycoon_trucklogistics:openViaTablet', k)
                                end
                            end
                        }
                    })
                end
            end

            function point:onExit()
                if spawnedPeds[k] then
                    if DoesEntityExist(spawnedPeds[k]) then
                        DeleteEntity(spawnedPeds[k])
                    end
                    spawnedPeds[k] = nil
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, ped in pairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:openViaTablet', function(empresaId)
	abertoViaTablet = true
	if empresaId then
		empresaAtual = empresaId
	end
	TriggerServerEvent('cidade_tycoon_trucklogistics:getData')
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:closeViaTablet', function()
	abertoViaTablet = false
	menuactive = false
	TriggerServerEvent('cidade_tycoon_trucklogistics:closeUI')
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:open', function(dados,update)
	-- Calcula a distancia e recompensa para cada contrato
	local x1,y1,z1 = table.unpack(GetEntityCoords(PlayerPedId()))
	for k,v in pairs(dados.trucker_available_contracts) do
		local x2,y2,z2 = table.unpack(Config.locais_entrega[v.coords_index])
		-- local distance = CalculateTravelDistanceBetweenPoints(x1,y1,z1, x2, y2, z2)
		-- if distance > 50 then
			distance = #(vector3(x1,y1,z1) - vector3(x2,y2,z2))
		-- end
		dados.trucker_available_contracts[k]['distance'] = tonumber(string.format("%.2f", (distance/1000)))
		dados.trucker_available_contracts[k]['reward'] = tonumber(string.format("%.f", (dados.trucker_available_contracts[k].distance * v.price_per_km)))
	end
	
	-- Abre NUI ou envia para o Tablet
	if abertoViaTablet then
		TriggerEvent('cidade_tycoon_tablet:client:truckLogisticsMessage', {
			showmenu = true,
			update = update,
			dados = dados,
			openFuelPage = openFuelPageOnLoad
		})
	else
		SendNUIMessage({ 
			showmenu = true,
			update = update,
			dados = dados,
			openFuelPage = openFuelPageOnLoad
		})
		if update == false then
			menuactive = true
			SetNuiFocus(true,true)
		end
	end
	openFuelPageOnLoad = false
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- CALLBACKS
-----------------------------------------------------------------------------------------------------------------------------------------

RegisterNUICallback('startJob', function(data, cb)
	if cooldown == nil then
		cooldown = true
		
		if not loading then
			if type(data) == 'table' then
				data.empresa = empresaAtual
			end
			TriggerServerEvent('cidade_tycoon_trucklogistics:startContract',data)
		else
			notify(Lang[Config.lang]['loading_trailer'], "primary")
			closeUI()
		end
		
		SetTimeout(500,function()
			cooldown = nil
		end)
	end
	cb('ok')
end)

RegisterNUICallback('upgradeSkill', function(data, cb)
	TriggerServerEvent('cidade_tycoon_trucklogistics:upgradeSkill',data)
	cb('ok')
end)

RegisterNUICallback('repairTruck', function(data, cb)
	if truck and not rentTruck then
		notify(Lang[Config.lang]['store_truck'], "error")
		cb('ok')
		return
	end
	TriggerServerEvent('cidade_tycoon_trucklogistics:repairTruck',data.id)
	cb('ok')
end)

RegisterNUICallback('buyTruck', function(data, cb)
	TriggerServerEvent('cidade_tycoon_trucklogistics:buyTruck',data)
	cb('ok')
end)

RegisterNUICallback('sellTruck', function(data, cb)
	if cooldown == nil then
		cooldown = true
		
		if truck and not rentTruck then
			notify(Lang[Config.lang]['store_truck_2'], "error")
			cb('ok')
			return
		end
		TriggerServerEvent('cidade_tycoon_trucklogistics:sellTruck',data)
		
		SetTimeout(500,function()
			cooldown = nil
		end)
	end
	cb('ok')
end)

RegisterNUICallback('fireDriver', function(data, cb)
	TriggerServerEvent('cidade_tycoon_trucklogistics:fireDriver',data.driver_id)
	cb('ok')
end)

RegisterNUICallback('spawnTruck', function(data, cb)
	if cooldown == nil then
		cooldown = true
		
		if not loading then
			TriggerServerEvent('cidade_tycoon_trucklogistics:spawnTruck',data.truck_id)
		else
			notify(Lang[Config.lang]['loading_truck'], "primary")
			closeUI()
		end
		
		SetTimeout(500,function()
			cooldown = nil
		end)
	end
	cb('ok')
end)

RegisterNUICallback('hireDriver', function(data, cb)
	TriggerServerEvent('cidade_tycoon_trucklogistics:hireDriver',data.driver_id)
	cb('ok')
end)

RegisterNUICallback('setDriver', function(data, cb)
	print("^3[TruckLogistics:Debug]^7 setDriver chamado com: " .. json.encode(data))
	if data.driver_id == '0' or data.driver_id == 0 then
		notify("Solicitando seleção de veículo...", "inform")
	end
	TriggerServerEvent('cidade_tycoon_trucklogistics:setDriver',data)
	cb('ok')
end)

RegisterNUICallback('depositMoney', function(data, cb)
	TriggerServerEvent('cidade_tycoon_trucklogistics:depositMoney',data)
	cb('ok')
end)

RegisterNUICallback('withdrawMoney', function(data, cb)
	if cooldown == nil then
		cooldown = true
		
		TriggerServerEvent('cidade_tycoon_trucklogistics:withdrawMoney')
		
		SetTimeout(500,function()
			cooldown = nil
		end)
	end
	cb('ok')
end)

RegisterNUICallback('loan', function(data, cb)
	if cooldown == nil then
		cooldown = true
		
		TriggerServerEvent('cidade_tycoon_trucklogistics:loan',data)
		
		SetTimeout(500,function()
			cooldown = nil
		end)
	end
	cb('ok')
end)

RegisterNUICallback('payLoan', function(data, cb)
	TriggerServerEvent('cidade_tycoon_trucklogistics:payLoan',data)
	cb('ok')
end)


RegisterNUICallback('resolveCrisis', function(data, cb)
    if not data or not data.driver_id or not data.option then cb('ok') return end
    TriggerServerEvent('cidade_tycoon_trucklogistics:resolveCrisis', { driver_id = tonumber(data.driver_id), option = tostring(data.option) })
    cb('ok')
end)

RegisterNUICallback('trainDriver', function(data, cb)
    if not data then cb('ok') return end
    TriggerServerEvent('cidade_tycoon_trucklogistics:trainDriver', tonumber(data))
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    closeUI()
    cb('ok')
end)

function closeUI()
	empresaAtual = nil
	menuactive = false
	SetNuiFocus(false,false)
	SendNUIMessage({ hidemenu = true })
	TriggerServerEvent('cidade_tycoon_trucklogistics:closeUI')
end

RegisterNetEvent('cidade_tycoon_trucklogistics:showFuelMenu', function(fuelStock, money)
	local payload = {
		action = 'updateFuel',
		fuelStock = fuelStock or 0,
		money = money or 0
	}
	if abertoViaTablet then
		TriggerEvent('cidade_tycoon_tablet:client:truckLogisticsMessage', payload)
	else
		SendNUIMessage(payload)
	end
end)

RegisterNUICallback('buyFuelBatch', function(data, cb)
	if not data.deliver then
		closeUI()
	else
		CreateThread(function() Wait(1200) TriggerServerEvent('cidade_tycoon_trucklogistics:openFuelMenu') end)
	end
	TriggerServerEvent('cidade_tycoon_trucklogistics:buyFuelBatch', tonumber(data.liters), tonumber(data.cost), data.deliver, empresaAtual)
	cb('ok')
end)

RegisterNUICallback('depositJerrycan', function(data, cb)
    TriggerServerEvent('cidade_tycoon_trucklogistics:depositJerrycan')
    CreateThread(function() Wait(1200) TriggerServerEvent('cidade_tycoon_trucklogistics:openFuelMenu') end)
    cb('ok')
end)

RegisterNUICallback('refreshFuel', function(data, cb)
    TriggerServerEvent('cidade_tycoon_trucklogistics:openFuelMenu')
    cb('ok')
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:startFuelMission', function(liters, coords, empresaId)
	if not IsEntityAVehicle(truck) then
		notify("Você precisa retirar o seu caminhão da garagem primeiro para iniciar esta missão!", "error")
		TriggerServerEvent('cidade_tycoon_trucklogistics:cancelFuelMission')
		return
	end

	if trailer or rentTruck then
		notify(Lang[Config.lang]['already_has_cargo'], "error")
		TriggerServerEvent('cidade_tycoon_trucklogistics:cancelFuelMission')
		return
	end

	-- Extract coordinates
	local rx, ry, rz, rh = coords.x, coords.y, coords.z, coords.w
	
	-- Spawn fuel trailer at the refinery
	local model = "tanker"
	trailer, trailer_blip = spawnVehicle(model, rx, ry, rz, rh, 1000, 1000, 1000, 1000, 479, 5, "Tanque de Combustível")
	if not trailer then
		notify("Erro ao criar o tanque de combustível na refinaria!", "error")
		TriggerServerEvent('cidade_tycoon_trucklogistics:cancelFuelMission')
		return
	end

	notify("Tanque pronto na refinaria! Vá buscar o combustível.", "success")
	PlaySoundFrontend(-1, "CHECKPOINT_BEAT", "HUD_MINI_GAME_SOUNDSET", 0)

	-- Set route to refinery first
	route_blip = AddBlipForCoord(rx, ry, rz)
	SetBlipSprite(route_blip, 1)
	SetBlipColour(route_blip, 5)
	SetBlipAsShortRange(route_blip, false)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Buscar Combustível")
	EndTextCommandSetBlipName(route_blip)
	SetBlipRoute(route_blip, true)

	local step = 1 -- 1: Ir até a refinaria engatar o reboque, 2: Levar de volta para a empresa
	local cargas = Config.empresas[empresaId]['coordenada_cargas']
	local cx, cy, cz, ch = table.unpack(cargas[1])
	
	-- Encontra uma vaga livre na empresa
	for i = 1, #cargas do
		local x, y, z, h = table.unpack(cargas[i])
		if IsSpawnPointClear({['x']=x,['y']=y,['z']=z}, 5.0) then
			cx, cy, cz, ch = x, y, z, h
			break
		end
	end

	Citizen.CreateThread(function()
		local timer = 5
		while IsEntityAVehicle(trailer) and IsEntityAVehicle(truck) do
			timer = 2000
			local ped = PlayerPedId()
			local veh = GetVehiclePedIsIn(ped, false)
			local playerCoords = GetEntityCoords(ped)

			local isAttached = IsEntityAttachedToEntity(truck, trailer)

			if step == 1 then
				if isAttached then
					step = 2
					RemoveBlip(route_blip)
					route_blip = AddBlipForCoord(cx, cy, cz)
					SetBlipSprite(route_blip, 1)
					SetBlipColour(route_blip, 5)
					SetBlipAsShortRange(route_blip, false)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentString("Entregar Combustível")
					EndTextCommandSetBlipName(route_blip)
					SetBlipRoute(route_blip, true)
					notify("Tanque engatado! Leve o combustível de volta para a empresa.", "success")
					PlaySoundFrontend(-1, "CHECKPOINT_BEAT", "HUD_MINI_GAME_SOUNDSET", 0)
				else
					local distToRefinery = #(playerCoords - vector3(rx, ry, rz))
					if distToRefinery <= 50.0 then
						timer = 5
						local tCoords = GetEntityCoords(trailer)
						DrawMarker(30, tCoords.x, tCoords.y, tCoords.z + 1.5, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.5, 255, 165, 0, 100, 1, 0, 0, 0)
					end
				end
			elseif step == 2 then
				if not isAttached then
					step = 1
					RemoveBlip(route_blip)
					local tCoords = GetEntityCoords(trailer)
					route_blip = AddBlipForCoord(tCoords.x, tCoords.y, tCoords.z)
					SetBlipSprite(route_blip, 1)
					SetBlipColour(route_blip, 5)
					SetBlipAsShortRange(route_blip, false)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentString("Buscar Tanque Desengatado")
					EndTextCommandSetBlipName(route_blip)
					SetBlipRoute(route_blip, true)
					notify("O tanque de combustível foi desengatado! Volte e engate-o novamente.", "error")
				else
					local distToCompany = #(playerCoords - vector3(cx, cy, cz))
					if distToCompany <= 50.0 then
						timer = 5
						if distToCompany <= 4.0 and veh == truck and angleDifference(GetEntityHeading(truck), ch) <= 15.0 and angleDifference(GetEntityHeading(trailer), ch) <= 15.0 then
							DrawMarker(30, cx, cy, cz - 0.6, 0, 0, 0, 90.0, ch, 0.0, 3.0, 1.0, 10.0, 0, 255, 0, 50, 0, 0, 0, 0)
							drawTxt("Pressione [E] para descarregar o combustível", 8, 0.5, 0.90, 0.50, 255, 255, 255, 180)
							
							if IsControlJustPressed(0, 38) then
								BringVehicleToHalt(truck, 2.5, 1, false)
								Wait(10)
								DoScreenFadeOut(500)
								Wait(500)
								DeleteVehicle(trailer)
								RemoveBlip(trailer_blip)
								RemoveBlip(route_blip)
								PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", 0)
								Wait(1000)
								DoScreenFadeIn(1000)
								CreateThreadNow(function()
									showScaleform("SUCESSO", "Combustível Entregue com Sucesso!", 3)
								end)
								trailer = nil
								trailer_blip = nil
								route_blip = nil
								TriggerServerEvent("cidade_tycoon_trucklogistics:finishFuelMission", liters)
								break
							end
						else
							drawTxt("Estacione de ré na vaga indicada", 8, 0.5, 0.90, 0.50, 255, 255, 255, 180)
							DrawMarker(30, cx, cy, cz - 0.6, 0, 0, 0, 90.0, ch, 0.0, 3.0, 1.0, 10.0, 255, 0, 0, 50, 0, 0, 0, 0)
						end
					end
				end
			end

			-- Verifica integridade do reboque
			local bodyhealth = GetVehicleBodyHealth(trailer)
			if bodyhealth <= 150 then
				PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", 0)
				notify("A carga de combustível foi destruída!", "error")
				RemoveBlip(trailer_blip)
				RemoveBlip(route_blip)
				DeleteVehicle(trailer)
				trailer = nil
				trailer_blip = nil
				route_blip = nil
				TriggerServerEvent('cidade_tycoon_trucklogistics:cancelFuelMission')
				break
			end

			-- Cancelar missão (Tecla F6 / Config)
			if IsControlPressed(0, Config.contratos['cancel_contrato']) then
				DeleteVehicle(trailer)
				RemoveBlip(trailer_blip)
				RemoveBlip(route_blip)
				trailer = nil
				trailer_blip = nil
				route_blip = nil
				TriggerServerEvent('cidade_tycoon_trucklogistics:cancelFuelMission')
				notify("Missão de combustível cancelada.", "error")
				break
			end

			Wait(timer)
		end

		-- Limpeza final caso saia do loop (ex: caminhão destruído)
		if IsEntityAVehicle(trailer) then
			DeleteVehicle(trailer)
		end
		if trailer_blip then
			RemoveBlip(trailer_blip)
		end
		if route_blip then
			RemoveBlip(route_blip)
		end
		trailer = nil
		trailer_blip = nil
		route_blip = nil
	end)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- PEGAR CAMINHÃO PRÓPRIO
-----------------------------------------------------------------------------------------------------------------------------------------
local updateTruckStatus = 0
RegisterNetEvent('cidade_tycoon_trucklogistics:spawnTruck', function(truck_data)
	if not IsEntityAVehicle(truck) then
		DeleteVehicle(truck)
		RemoveBlip(truck_blip)
		truck = nil
		truck_blip = nil
		rentTruck = false
	end
	if truck then
		notify(Lang[Config.lang]['already_has_truck'], "error")
		return
	end
	
	loading = true
	local garagem = Config.empresas[empresaAtual]['coordenada_garagem']
	local i = #garagem
	local x,y,z,h
	while i > 0 do
		x,y,z,h = table.unpack(garagem[i])
		local checkPos = IsSpawnPointClear({['x']=x,['y']=y,['z']=z},5.001)
		if checkPos == false then
			if i <= 1 then
				notify(Lang[Config.lang]['occupied_places'], "error")
				loading = false
				return
			end
		else
			break
		end
		i = i - 1
	end
	truck,truck_blip = spawnVehicle(truck_data.truck_name,x,y,z,h,truck_data.body,truck_data.engine,truck_data.transmission,truck_data.wheels,477,26,Lang[Config.lang]['truck_blip'])
	notify(Lang[Config.lang]['already_is_in_garage'], "success")
	loading = false

	local timer = 5
	local engineH = 1000
	while IsEntityAVehicle(truck) do
		timer = 2000
		local ped = PlayerPedId()
		veh = GetVehiclePedIsIn(ped,false)
		if veh == truck then
			engineH = GetVehicleEngineHealth(truck)
			for k,v in pairs(Config.empresas) do
				for k,mark in pairs(v.coordenada_garagem) do
					local x,y,z = table.unpack(mark)
					local distance = #(GetEntityCoords(PlayerPedId()) - vector3(x,y,z))
					if distance <= 20.0 then
						timer = 5
						DrawMarker(39,x,y,z,0,0,0,0.0,0,0,2.0,2.0,2.0,255,0,0,50,0,0,0,1)
						if distance <= 5.0 then
							drawTxt(Lang[Config.lang]['press_e_to_store_truck'], 8,0.5,0.90,0.50,255,255,255,180)
							if IsControlJustPressed(0,38) then
								TriggerServerEvent("cidade_tycoon_trucklogistics:updateTruckStatus",truck_data,GetVehicleEngineHealth(truck),GetVehicleBodyHealth(truck))
								DeleteVehicle(truck)
								RemoveBlip(truck_blip)
								truck = nil
								truck_blip = nil
							end
						end
					else
						if updateTruckStatus == 0 and engineH ~= GetVehicleEngineHealth(truck) then
							updateTruckStatus = 3
							TriggerServerEvent("cidade_tycoon_trucklogistics:updateTruckStatus",truck_data,GetVehicleEngineHealth(truck),GetVehicleBodyHealth(truck))
							engineH = GetVehicleEngineHealth(truck)
						end
					end
				end
			end
		end
		Citizen.Wait(timer)
	end
	DeleteEntity(truck)
	RemoveBlip(truck_blip)
	truck = nil
	truck_blip = nil
end)

Citizen.CreateThread(function()
	while true do
		timer = 2500
		if updateTruckStatus > 0 then
			updateTruckStatus = updateTruckStatus - 1
		end
		Citizen.Wait(timer)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INICIAR TRABALHO
-----------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent('cidade_tycoon_trucklogistics:startContract', function(data,job_distance,reward,truck_data)
	local isRental = (tonumber(data.contract_type) == 0 or data.contract_type == false or data.contract_type == '0')
	local key = empresaAtual
	if not IsEntityAVehicle(trailer) then
		DeleteVehicle(trailer)
		RemoveBlip(trailer_blip)
		RemoveBlip(route_blip)
		trailer = nil
		trailer_blip = nil
		route_blip = nil
		rentTruck = false
	end
	if trailer or rentTruck then
		notify(Lang[Config.lang]['already_has_cargo'], "error")
		TriggerServerEvent('cidade_tycoon_trucklogistics:cancelContract')
		return
	end

	if not IsEntityAVehicle(truck) then
		DeleteVehicle(truck)
		RemoveBlip(truck_blip)
		RemoveBlip(route_blip)
		truck = nil
		truck_blip = nil
		route_blip = nil
		rentTruck = false
	end
	if isRental and truck then
		notify(Lang[Config.lang]['must_store_truck'], "error")
		TriggerServerEvent('cidade_tycoon_trucklogistics:cancelContract')
		return
	end
	if not isRental and not IsEntityAVehicle(truck) then
		notify(Lang[Config.lang]['loading_truck'], "error")
		TriggerServerEvent('cidade_tycoon_trucklogistics:cancelContract')
		return
	end

	Citizen.CreateThreadNow(function()
		resetLoading()
	end)

	loading = true
	local x,y,z,h
	if isRental then
		local garagem = Config.empresas[key]['coordenada_garagem']
		local i = #garagem
		while i > 0 do
			x,y,z,h = table.unpack(garagem[i])
			local checkPos = IsSpawnPointClear({['x']=x,['y']=y,['z']=z},5.001)
			if checkPos == false then
				if i <= 1 then
					notify(Lang[Config.lang]['occupied_places'], 'error')
					loading = false
					TriggerServerEvent('cidade_tycoon_trucklogistics:cancelContract')
					return
				end
			else
				break
			end
			i = i - 1
		end
		truck,truck_blip = spawnVehicle(data.truck,x,y,z,h,1000,1000,1000,1000,477,26,Lang[Config.lang]['rented_truck_blip'])
		if not truck then
			loading = false
			TriggerServerEvent('cidade_tycoon_trucklogistics:cancelContract')
			return
		end
		rentTruck = true
	end
	
	local cargas = Config.empresas[key]['coordenada_cargas']
	i = #cargas
	while i > 0 do
		x,y,z,h = table.unpack(cargas[i])
		local checkPos = IsSpawnPointClear({['x']=x,['y']=y,['z']=z},5.001)
		if checkPos == false then
			if i <= 1 then
				if rentTruck then
					DeleteVehicle(truck)
					RemoveBlip(truck_blip)
					truck = nil
					truck_blip = nil
					rentTruck = false
				end
				notify(Lang[Config.lang]['occupied_places'], "error")
				loading = false
				TriggerServerEvent('cidade_tycoon_trucklogistics:cancelContract')
				return
			end
		else
			break
		end
		i = i - 1
	end
	trailer,trailer_blip = spawnVehicle(data.trailer,x,y,z,h,1000,1000,1000,1000,479,26,Lang[Config.lang]['cargo_blip'])
	if not trailer then
		if isRental and truck then DeleteVehicle(truck) end
		loading = false
		TriggerServerEvent('cidade_tycoon_trucklogistics:cancelContract')
		return
	end
	notify(Lang[Config.lang]['started_job'], "success")
	loading = false


	local timer = 5
	x,y,z,h = table.unpack(Config.locais_entrega[data.coords_index])

	route_blip = AddBlipForCoord(x,y,z)
	SetBlipSprite(route_blip,1)
	SetBlipColour(route_blip,5)
	SetBlipAsShortRange(route_blip,false)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(Lang[Config.lang]['destination_blip'])
	EndTextCommandSetBlipName(route_blip)
	SetBlipRoute(route_blip,true)
	closeUI()
	while IsEntityAVehicle(trailer) do 
		timer = 2000
		local ped = PlayerPedId()
		veh = GetVehiclePedIsIn(ped,false)
		local distance = #(GetEntityCoords(ped) - vector3(x,y,z))

		if distance <= 50.0 then
			timer = 5
			if distance <= 4.0 and veh == truck and angleDifference(GetEntityHeading(truck), h) <= 15.0 and angleDifference(GetEntityHeading(trailer), h) <= 15.0 and IsEntityAttachedToEntity(truck,trailer) then
				DrawMarker(30,x,y,z-0.6,0,0,0,90.0,h,0.0,3.0,1.0,10.0,0,255,0,50,0,0,0,0)
				drawTxt(Lang[Config.lang]['press_e_to_park'], 8,0.5,0.90,0.50,255,255,255,180)
				if IsControlJustPressed(0,38) then
					BringVehicleToHalt(truck, 2.5, 1, false)
					Citizen.Wait(10)
					DoScreenFadeOut(500)
					Citizen.Wait(500)
					local trailerHealth = GetVehicleBodyHealth(trailer)
					DeleteVehicle(trailer)
					RemoveBlip(trailer_blip)
					RemoveBlip(route_blip)
					PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", 0)
					Citizen.Wait(1000)
					DoScreenFadeIn(1000)
					Citizen.CreateThreadNow(function()
						showScaleform(Lang[Config.lang]['success'], Lang[Config.lang]['finished_job'], 3)
					end)
					trailer = nil
					trailer_blip = nil
					route_blip = nil
					TriggerServerEvent("cidade_tycoon_trucklogistics:finishJob",data,job_distance,reward,truck_data,GetVehicleEngineHealth(truck),GetVehicleBodyHealth(truck),trailerHealth)
					break
				end
			else
				drawTxt(Lang[Config.lang]['park_your_truck'], 8,0.5,0.90,0.50,255,255,255,180)
				DrawMarker(30,x,y,z-0.6,0,0,0,90.0,h,0.0,3.0,1.0,10.0,255,0,0,50,0,0,0,0)
			end
		end
		
		local bodyhealth = GetVehicleBodyHealth(trailer)
		if bodyhealth <= 150 then
			PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", 0)
			notify(Lang[Config.lang]['failed'], "error")
			
			RemoveBlip(trailer_blip)
			RemoveBlip(route_blip)
			DeleteVehicle(trailer)
			trailer = nil
			trailer_blip = nil
			route_blip = nil
			TriggerServerEvent('cidade_tycoon_trucklogistics:cancelContract')
			break
		end

		if IsControlPressed(0,Config.contratos['cancel_contrato']) then
			DeleteVehicle(trailer)
			RemoveBlip(trailer_blip)
			RemoveBlip(route_blip)
			trailer = nil
			trailer_blip = nil
			route_blip = nil
			rentTruck = false
			TriggerServerEvent('cidade_tycoon_trucklogistics:cancelContract')
			if isRental then
				DeleteVehicle(truck)
				RemoveBlip(truck_blip)
				truck = nil
				truck_blip = nil
			end
			break
		end
		Wait(timer)
	end

	while IsEntityAVehicle(truck) and isRental do 
		timer = 2000
		local ped = PlayerPedId()
		veh = GetVehiclePedIsIn(ped,false)
		for k,v in pairs(Config.empresas) do
			for k,mark in pairs(v.coordenada_garagem) do
				local x,y,z = table.unpack(mark)
				local distance = #(GetEntityCoords(PlayerPedId()) - vector3(x,y,z))
				timer = 5
				if veh == truck and distance <= 20.0 then
					DrawMarker(39,x,y,z,0,0,0,0.0,0,0,2.0,2.0,2.0,255,0,0,50,0,0,0,1)
					if distance <= 5.0 then
						drawTxt(Lang[Config.lang]['press_e_to_store_truck'], 8,0.5,0.90,0.50,255,255,255,180)
						if IsControlJustPressed(0,38) then
							DeleteVehicle(truck)
							RemoveBlip(truck_blip)
							RemoveBlip(route_blip)
							truck = nil
							truck_blip = nil
							route_blip = nil
							rentTruck = false
						end
					end
				else
					drawTxt(Lang[Config.lang]['bring_back'], 8,0.5,0.90,0.50,255,255,255,180)
				end
			end
		end
		Wait(timer)
	end

	DeleteVehicle(trailer)
	RemoveBlip(trailer_blip)
	RemoveBlip(route_blip)
	trailer = nil
	trailer_blip = nil
	route_blip = nil
	rentTruck = false
	if isRental then
		DeleteVehicle(truck)
		RemoveBlip(truck_blip)
		truck = nil
		truck_blip = nil
	end
end)

function resetLoading()
	Citizen.Wait(50000)
	if loading == true then
		notify(Lang[Config.lang]['loading_fail'], "error")
		loading = false
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNÇÕES
-----------------------------------------------------------------------------------------------------------------------------------------

function showScaleform(title, desc, sec)
	function Initialize(scaleform)
		local scaleform = RequestScaleformMovie(scaleform)

		while not HasScaleformMovieLoaded(scaleform) do
			Citizen.Wait(0)
		end
		PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
		PushScaleformMovieFunctionParameterString(title)
		PushScaleformMovieFunctionParameterString(desc)
		PopScaleformMovieFunctionVoid()
		return scaleform
	end
	scaleform = Initialize("mp_big_message_freemode")
	while sec > 0 do
		sec = sec - 0.02
		Citizen.Wait(0)
		DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
	end
	SetScaleformMovieAsNoLongerNeeded(scaleform)
end

function addBlip(x,y,z,idtype,idcolor,text,scale,route)
	local blip = AddBlipForCoord(x,y,z)
	SetBlipSprite(blip,idtype)
	SetBlipAsShortRange(blip,true)
	SetBlipColour(blip,idcolor)
	SetBlipScale(blip,scale)

	if route then
		SetBlipRoute(blip,true)
	end

	if text then
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(text)
		EndTextCommandSetBlipName(blip)
	end
	return blip
end

function EnumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance)
	local nearbyEntities = {}

	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		local playerPed = PlayerPedId()
		coords = GetEntityCoords(playerPed)
	end

	for k,entity in pairs(entities) do
		local distance = #(coords - GetEntityCoords(entity))

		if distance <= maxDistance then
			table.insert(nearbyEntities, isPlayerEntities and k or entity)
		end
	end

	return nearbyEntities
end

local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end

		enum.destructor = nil
		enum.handle = nil
	end
}

function EnumerateEntities(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
		local iter, id = initFunc()
		if not id or id == 0 then
			disposeFunc(iter)
			return
		end

		local enum = {handle = iter, destructor = disposeFunc}
		setmetatable(enum, entityEnumerator)
		local next = true

		repeat
			coroutine.yield(id)
			next, id = moveFunc(iter)
		until not next

		enum.destructor, enum.handle = nil, nil
		disposeFunc(iter)
	end)
end

function EnumerateVehicles()
	return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

GetVehicles = function()
	local vehicles = {}

	for vehicle in EnumerateVehicles() do
		table.insert(vehicles, vehicle)
	end

	return vehicles
end

GetVehiclesInArea = function(coords, maxDistance) return EnumerateEntitiesWithinDistance(GetVehicles(), false, coords, maxDistance) end
IsSpawnPointClear = function(coords, maxDistance) return #GetVehiclesInArea(coords, maxDistance) == 0 end

local anims = {}

function playAnim(upper, seq, looping)
    stopAnim(upper)

    local flags = 0
    if upper then flags = flags+48 end
    if looping then flags = flags+1 end

    Citizen.CreateThread(function()
      for k,v in pairs(seq) do
        local dict = v[1]
        local name = v[2]
        local loops = v[3] or 1

        for i=1,loops do
            local first = (k == 1 and i == 1)
            local last = (k == #seq and i == loops)

            -- request anim dict
            RequestAnimDict(dict)
            local i = 0
            while not HasAnimDictLoaded(dict) and i < 1000 do -- max time, 10 seconds
              Citizen.Wait(10)
              RequestAnimDict(dict)
              i = i+1
            end

            -- play anim
            if HasAnimDictLoaded(dict)then
              local inspeed = 8.0001
              local outspeed = -8.0001
              if not first then inspeed = 2.0001 end
              if not last then outspeed = 2.0001 end

              TaskPlayAnim(GetPlayerPed(-1),dict,name,inspeed,outspeed,-1,flags,0,0,0,0)
            end

            Citizen.Wait(0)
            while GetEntityAnimCurrentTime(GetPlayerPed(-1),dict,name) <= 0.95 and IsEntityPlayingAnim(GetPlayerPed(-1),dict,name,3) and anims[id] do
              Citizen.Wait(0)
            end
          end
      end
    end)
end
function stopAnim(upper)
	anims = {} -- stop all sequences
	if upper then
	  	ClearPedSecondaryTask(GetPlayerPed(-1))
	else
	  	ClearPedTasks(GetPlayerPed(-1))
	end
end

function print_table(node)
    -- to make output beautiful
    local function tab(amt)
        local str = ""
        for i=1,amt do
            str = str .. "\t"
        end
        return str
    end
 
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"
 
    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end
 
        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then
               
                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end
 
                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""
               
                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end
 
                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. tab(depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. tab(depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. tab(depth) .. key .. " = '"..tostring(v).."'"
                end
 
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. tab(depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. tab(depth-1) .. "}"
                end
            end
 
            cur_index = cur_index + 1
        end
 
        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end
 
    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)
   
    print(output_str)
end
