local function normalizePlate(plate)
    return exports.cidade_tycoon_core:NormalizePlate(plate)
end

-- Register client event to fix visual damage
RegisterNetEvent('cidade_tycoon_maintenance:client:fixVisualDamage', function(plate)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    -- If not in the vehicle, try to find it nearby
    if veh == 0 then
        local vehicles = GetGamePool('CVehicle')
        for _, v in ipairs(vehicles) do
            if DoesEntityExist(v) and normalizePlate(GetVehicleNumberPlateText(v)) == normalizePlate(plate) then
                veh = v
                break
            end
        end
    end

    if veh == 0 then
        lib.notify({ title = 'Lataria', description = 'Veiculo nao encontrado proximo.', type = 'error' })
        return
    end

    -- Fix all visual damage
    SetVehicleFixed(veh)
    SetVehicleDeformationFixed(veh)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehicleEngineHealth(veh, 1000.0)

    -- Fix all doors
    local numDoors = GetVehicleNumberOfDoors(veh)
    if numDoors then
        for door = 0, numDoors - 1 do
            SetVehicleDoorBroken(veh, door, false)
            SetVehicleDoorControl(veh, door, 0, false)
        end
    end

    -- Fix all windows
    for window = 0, 5 do
        if not IsVehicleWindowIntact(veh, window) then
            FixVehicleWindow(veh, window)
        end
    end

    -- Fix all tires
    for wheel = 0, 5 do
        SetVehicleTyreFixed(veh, wheel)
    end

    lib.notify({ title = 'Lataria', description = 'Lataria reparada visualmente.', type = 'success' })
end)
