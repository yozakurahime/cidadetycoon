Recording = {}
Recording.Active = false
Recording.Data = {}
Recording.StartTime = 0
Recording.VehicleModel = nil
Recording.PedAppearance = nil
Recording.CurrentAnim = nil

function Recording.Start()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        Utils.ShowNotification("~r~Você precisa estar em um veículo!")
        return false
    end

    Recording.Active = true
    Recording.Data = {}
    Recording.StartTime = GetGameTimer()
    Recording.VehicleModel = GetEntityModel(veh)
    Recording.PedAppearance = Utils.GetPedAppearance(ped)
    Recording.CurrentAnim = nil

    CreateThread(function()
        while Recording.Active do
            local currentVeh = GetVehiclePedIsIn(PlayerPedId(), false)
            if currentVeh == 0 then
                Recording.Stop(false)
                Utils.ShowNotification("~r~Gravação cancelada: saiu do veículo.")
                break
            end

            local now = GetGameTimer()
            local elapsed = now - Recording.StartTime
            local pos = GetEntityCoords(currentVeh)
            local rot = GetEntityRotation(currentVeh, 2)
            local _, lowBeams, highBeams = GetVehicleLightsState(currentVeh)
            local indicatorState = GetVehicleIndicatorLights(currentVeh)
            local isSirenOn = IsVehicleSirenOn(currentVeh)
            local currentAnim = Recording.CurrentAnim or Utils.GetCurrentPedAnim(PlayerPedId())

            table.insert(Recording.Data, {
                time     = elapsed,
                pos      = { x = pos.x, y = pos.y, z = pos.z },
                rot      = { x = rot.x, y = rot.y, z = rot.z },
                throttle = (GetVehicleThrottleOffset and GetVehicleThrottleOffset(currentVeh)) or GetControlNormal(0, 71),
                brake    = GetControlNormal(0, 72),
                steer    = (GetVehicleSteeringAngle and GetVehicleSteeringAngle(currentVeh)) or 0.0,
                gear     = (GetVehicleCurrentGear and GetVehicleCurrentGear(currentVeh)) or 1,
                rpm      = (GetVehicleCurrentRpm and GetVehicleCurrentRpm(currentVeh)) or 0.0,
                lowBeams = lowBeams == 1,
                highBeams= highBeams == 1,
                indicators = indicatorState,
                siren    = isSirenOn,
                anim     = currentAnim
            })

            Wait(Config.Record.RecordIntervalMs)
        end
    end)
    return true
end

function Recording.Stop(save)
    local elapsed = GetGameTimer() - Recording.StartTime
    Recording.Active = false
    if save and #Recording.Data > 0 then
        return Recording.Data, elapsed, Recording.VehicleModel, Recording.PedAppearance
    end
    return nil, 0, nil, nil
end

function Recording.GetElapsed()
    if not Recording.Active then return 0 end
    return GetGameTimer() - Recording.StartTime
end

exports('SetDriverAnim', function(dict, name)
    Recording.CurrentAnim = { dict = dict, name = name }
end)

