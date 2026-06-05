local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end
		enum.destructor = nil
		enum.handle = nil
	end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
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

function EnumerateObjects()
	return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
	return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
	return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function EnumeratePickups()
	return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end


local closestPed = nil
isSelectingActive = false


Citizen.CreateThread(function()
    local plyPed = PlayerPedId()
    while true do
		if(isSelectingActive) then
			local plyPos = GetEntityCoords(plyPed)
			
			local xClosestDistance = 5.0
			local yClosestDistance = 5.0

			for currentPed in EnumeratePeds() do
				if(IsPedAPlayer(currentPed)) then
					local currentPedCoords = GetPedBoneCoords(currentPed, 24818, 0.0, 0.0, 0.0)

					local distance = GetDistanceBetweenCoords(currentPedCoords, plyPos, true)

					if(distance < 10.0) then
						local _, screenX, screenY = GetScreenCoordFromWorldCoord(currentPedCoords.x, currentPedCoords.y, currentPedCoords.z)
						
						if(screenX > 0 and screenY > 0) then
							local mouseX, mouseY = GetNuiCursorPosition()
							
							local screenWidth, screenHeight = GetActiveScreenResolution()
							
							if(mouseX <= screenWidth and mouseY <= screenHeight) then
								mouseX = mouseX/screenWidth
								mouseY = mouseY/screenHeight

								local xScreenDistance = math.abs(mouseX-screenX)
								local yScreenDistance = math.abs(mouseY-screenY)

								if(xScreenDistance < 0.03 and yScreenDistance < 0.1) then
									if(xClosestDistance > xScreenDistance and yClosestDistance > yScreenDistance) then
										xClosestDistance = xScreenDistance
										yClosestDistance = yScreenDistance
										closestPed = currentPed
									end
								else
									if(currentPed == closestPed) then
										closestPed = nil
									end
								end
							end
						end
					end
				end
			end
		
			Citizen.Wait(100)
		else
			plyPed = PlayerPedId()
			Citizen.Wait(1000)
		end


        Citizen.Wait(0)
    end
end)

function PlayerSelezionato()
   return lastgiocatore
end

function CercaPlayer()
    lastgiocatore = nil
    SetNuiFocus(false, true)
	isSelectingActive = true
	
	Citizen.CreateThread(function() 	
		while true do
			local timer = 1000	
			if isSelectingActive then 
				timer = 5
				if(closestPed) then
					local pedCoords = GetPedBoneCoords(closestPed, 24817, 0.0, 0.0, 0.0)
					DrawMarker(1, 
					pedCoords.x, pedCoords.y, pedCoords.z - 1.0, 
					0.0, 0.0, 0.0,
					0.0, 0.0, 0.0,
					1.0, 1.0, 2.0,
					243, 89, 0, 100, 
					false, true, 2, false, nil, nil, nil)
				end

				DisableControlAction(0, 24, true)
				DisableControlAction(0, 25, true)
				DisableControlAction(0, 263, true)
				DisableControlAction(0, 140, true)
				DisableControlAction(0, 141, true)
				DisableControlAction(0, 142, true)
				DisableControlAction(0, 143, true)
				DisableControlAction(0, 200, true)
	            DisablePlayerFiring(PlayerPedId(), true)
				
				if(IsDisabledControlJustReleased(0, 24)) then
					DisablePlayerFiring(PlayerPedId(), true)
					local targetPlayer = NetworkGetPlayerIndexFromPed(closestPed)
					local targetId = GetPlayerServerId(targetPlayer)

					isSelectingActive = false
					
					SetNuiFocus(false, false)
					lastgiocatore = targetId
					break
				end
				if IsControlJustReleased(0, 322) or IsControlJustReleased(0, 177) then
					isSelectingActive = false
					SetNuiFocus(false, false)
					lastgiocatore = 'nil'
					break
				end			
			end
			Citizen.Wait(timer)
		end
	end)	
end

exports("PlayerSelezionato",PlayerSelezionato)
exports("CercaPlayer", CercaPlayer)
