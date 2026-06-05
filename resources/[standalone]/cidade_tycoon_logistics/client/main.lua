RegisterNetEvent('cidade_tycoon_logistics:client:spawnNPCDriver', function(data)
    -- data: deliveryId, employeeName, plate, route
    local model = joaat('s_m_m_trucker_01')
    local vehicleModel = joaat('mule') -- Fallback if not specified or should be from plate
    
    lib.requestModel(model)
    lib.requestModel(vehicleModel)

    local spawnCoords = data.route.origin
    local vehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetVehicleNumberPlateText(vehicle, data.plate)
    
    local ped = CreatePedInsideVehicle(vehicle, 4, model, -1, true, false)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    -- Task the NPC to drive to destination
    TaskVehicleDriveToCoord(ped, vehicle, data.route.destination.x, data.route.destination.y, data.route.destination.z, 20.0, 0, vehicleModel, 786603, 1.0, true)
    
    -- Notify system of physical spawn
    TriggerServerEvent('cidade_tycoon_logistics:server:reportPhysicalNPC', data.deliveryId, NetworkGetNetworkIdFromEntity(ped), NetworkGetNetworkIdFromEntity(vehicle))
    
    exports.qbx_core:Notify(('Motorista %s iniciou a rota!'):format(data.employeeName), 'inform')
end)
