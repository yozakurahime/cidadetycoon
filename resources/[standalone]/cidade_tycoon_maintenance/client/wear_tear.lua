local isMonitoring = false
local lastCoords = nil
local lastPlate = nil

local function monitorVehicleStatus()
    if isMonitoring then return end
    isMonitoring = true
    
    CreateThread(function()
        while isMonitoring do
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                local plate = GetVehicleNumberPlateText(veh)
                local coords = GetEntityCoords(veh)
                
                if lastPlate == plate and lastCoords then
                    local dist = #(coords - lastCoords) / 1000.0 -- km
                    if dist > 0.01 then -- Process every 10 meters
                        -- In production, we'd batch this to avoid constant server calls
                        lib.callback.await('cidade_tycoon_maintenance:server:processWearTear', false, plate, dist, 1.0)
                        lastCoords = coords
                    end
                else
                    lastPlate = plate
                    lastCoords = coords
                end
            else
                lastPlate = nil
                lastCoords = nil
            end
            
            Wait(5000)
        end
    end)
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    monitorVehicleStatus()
end)
