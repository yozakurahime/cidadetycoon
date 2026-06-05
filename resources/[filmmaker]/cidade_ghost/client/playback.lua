Playback = {}
Playback.ActiveGhosts = {}

function Playback.Start(replayEntry, customCollision)
    if not replayEntry or not replayEntry.frames or #replayEntry.frames == 0 then return end
    local replayId = replayEntry.id
    if not replayId then return end

    -- Stop specific replay if already running
    Playback.Stop(replayId)

    local ghostState = {
        id = replayId,
        active = true,
        paused = false,
        speed = 1.0,
        collision = (customCollision ~= nil) and customCollision or Config.Replay.EnableCollision,
        data = replayEntry.frames,
        model = replayEntry.model,
        pedAppearance = replayEntry.pedAppearance,
        ghostVeh = nil,
        ghostPed = nil,
        ghostBlip = nil,
        startTime = GetGameTimer(),
        currentTime = 0,
        wheelRot = 0.0,
        lastPos = nil
    }

    Playback.ActiveGhosts[replayId] = ghostState

    CreateThread(function()
        -- 1. Load vehicle model
        local hash = ghostState.model
        if type(hash) == "string" then hash = GetHashKey(hash) end
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) do
            Wait(10)
            timeout = timeout + 10
            if timeout > 10000 then
                Utils.ShowNotification("~r~Erro: modelo do veículo não carregado.")
                Playback.Stop(replayId)
                return
            end
        end

        -- 2. Load driver ped model
        local pedHash = `csb_car3guy2` -- default fallback
        if ghostState.pedAppearance and ghostState.pedAppearance.model then
            pedHash = ghostState.pedAppearance.model
            if type(pedHash) == "string" then pedHash = GetHashKey(pedHash) end
        end
        RequestModel(pedHash)
        timeout = 0
        while not HasModelLoaded(pedHash) do
            Wait(10)
            timeout = timeout + 10
            if timeout > 5000 then
                pedHash = `csb_car3guy2` -- revert to default fallback
                RequestModel(pedHash)
                while not HasModelLoaded(pedHash) do Wait(10) end
                break
            end
        end

        if not ghostState.active then return end

        -- 3. Create vehicle entity
        local f1 = ghostState.data[1]
        local veh = CreateVehicle(hash, f1.pos.x, f1.pos.y, f1.pos.z, f1.rot.z or 0.0, false, false)
        if not DoesEntityExist(veh) then
            Utils.ShowNotification("~r~Erro ao criar veículo ghost.")
            Playback.Stop(replayId)
            return
        end

        ghostState.ghostVeh = veh
        ghostState.lastPos = vector3(f1.pos.x, f1.pos.y, f1.pos.z)

        -- Initial properties (no permanent freezing to keep sounds playing)
        SetEntityAlpha(veh, Config.Replay.VehicleAlpha, false)
        -- Always enable collision for the world/ground so the tires rest on the pavement
        SetEntityCollision(veh, true, false)
        SetEntityInvincible(veh, true)
        SetVehicleDoorsLocked(veh, 10)
        SetVehicleEngineOn(veh, true, true, false)
        FreezeEntityPosition(veh, false)

        -- 4. Create driver ped
        local driver = CreatePed(4, pedHash, f1.pos.x, f1.pos.y, f1.pos.z, f1.rot.z or 0.0, false, false)
        if DoesEntityExist(driver) then
            ghostState.ghostPed = driver
            SetPedIntoVehicle(driver, veh, -1)
            SetEntityAlpha(driver, Config.Replay.VehicleAlpha, false)
            SetEntityCollision(driver, false, false)
            SetEntityInvincible(driver, true)
            SetBlockingOfNonTemporaryEvents(driver, true)

            -- Apply appearance clones
            if ghostState.pedAppearance then
                Utils.SetPedAppearance(driver, ghostState.pedAppearance)
            end
        end

        -- 5. Create blip
        if Config.General.GhostBlips then
            local blip = AddBlipForEntity(veh)
            SetBlipSprite(blip, 326)
            SetBlipColour(blip, 0)
            SetBlipScale(blip, 0.7)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName("Ghost")
            EndTextCommandSetBlipName(blip)
            ghostState.ghostBlip = blip
        end

        SetModelAsNoLongerNeeded(hash)
        SetModelAsNoLongerNeeded(pedHash)

        -- 6. Main loop
        local lastTime = GetGameTimer()

        while ghostState.active and DoesEntityExist(veh) do
            -- Continuously enforce transparent & collision flags
            -- Keep world collision active so tires touch the ground and spin naturally
            SetEntityCollision(veh, true, false)
            SetEntityAlpha(veh, Config.Replay.VehicleAlpha, false)
            if DoesEntityExist(driver) then
                SetEntityAlpha(driver, Config.Replay.VehicleAlpha, false)
                SetEntityCollision(driver, false, false)
            end

            -- If collision option is OFF in menu, disable collision against players, other vehicles and props frame-by-frame
            if not ghostState.collision then
                local playerPed = PlayerPedId()
                if DoesEntityExist(playerPed) then
                    SetEntityNoCollisionEntity(veh, playerPed, true)
                end
                local playerVeh = GetVehiclePedIsIn(playerPed, false)
                if playerVeh ~= 0 and DoesEntityExist(playerVeh) then
                    SetEntityNoCollisionEntity(veh, playerVeh, true)
                end
                local vehicles = GetGamePool('CVehicle')
                for i = 1, #vehicles do
                    local otherVeh = vehicles[i]
                    if otherVeh ~= veh and DoesEntityExist(otherVeh) then
                        SetEntityNoCollisionEntity(veh, otherVeh, true)
                    end
                end
                local peds = GetGamePool('CPed')
                for i = 1, #peds do
                    local otherPed = peds[i]
                    if otherPed ~= driver and DoesEntityExist(otherPed) then
                        SetEntityNoCollisionEntity(veh, otherPed, true)
                    end
                end
                local objects = GetGamePool('CObject')
                for i = 1, #objects do
                    local otherObj = objects[i]
                    if DoesEntityExist(otherObj) then
                        SetEntityNoCollisionEntity(veh, otherObj, true)
                    end
                end
            end

            local now = GetGameTimer()
            local dt = (now - lastTime) * ghostState.speed
            lastTime = now

            if not ghostState.paused then
                ghostState.currentTime = ghostState.currentTime + dt
            end

            local maxTime = ghostState.data[#ghostState.data].time
            if ghostState.currentTime > maxTime then
                ghostState.currentTime = 0
            end

            -- Match current frame
            local idx = nil
            for i = 1, #ghostState.data - 1 do
                if ghostState.data[i].time <= ghostState.currentTime and ghostState.data[i+1].time >= ghostState.currentTime then
                    idx = i
                    break
                end
            end

            if idx then
                local fa = ghostState.data[idx]
                local fb = ghostState.data[idx + 1]
                local frameDt = fb.time - fa.time
                local t = 0.0
                if frameDt > 0 then t = (ghostState.currentTime - fa.time) / frameDt end

                local posA = vector3(fa.pos.x, fa.pos.y, fa.pos.z)
                local posB = vector3(fb.pos.x, fb.pos.y, fb.pos.z)
                local rotA = vector3(fa.rot.x, fa.rot.y, fa.rot.z)
                local rotB = vector3(fb.rot.x, fb.rot.y, fb.rot.z)

                local pos = Utils.LerpVector3(posA, posB, t)
                local rot = Utils.LerpRotation(rotA, rotB, t)

                -- Calculate velocity vector for engine audio
                local vel = vector3(0, 0, 0)
                if frameDt > 0 then
                    vel = (posB - posA) / (frameDt / 1000.0)
                end

                local speed = #(vel)

                -- Apply transform
                if not ghostState.paused then
                    local currentPos = GetEntityCoords(veh)
                    local drift = #(currentPos - pos)
                    
                    -- Only teleport if the physical position drifted by more than 5cm.
                    -- This allows the physics engine to run continuously, which naturally spins the wheels
                    -- and prevents them from locking up or detaching due to frame-by-frame teleports.
                    if drift > 0.05 then
                        SetEntityCoordsNoOffset(veh, pos.x, pos.y, pos.z + 0.02, true, true, true)
                    end
                    
                    SetEntityRotation(veh, rot.x, rot.y, rot.z, 2, true)
                    SetEntityVelocity(veh, vel.x, vel.y, vel.z)
                    
                    -- Release handbrake to let physics engine spin the wheels freely by default
                    SetVehicleHandbrake(veh, false)
                    
                    local isBurnout = fa.throttle and fa.throttle > 0.1 and fa.brake and fa.brake > 0.1 and speed < 3.0
                    SetVehicleBurnout(veh, isBurnout == true)

                    -- Calculate 2D slide/drift detection (angle between heading and velocity)
                    local forward = GetEntityForwardVector(veh)
                    local forward2D = vector2(forward.x, forward.y)
                    local vel2D = vector2(vel.x, vel.y)
                    local lenF = #forward2D
                    local lenV = #vel2D
                    
                    local isSliding = false
                    if lenF > 0.01 and lenV > 0.01 then
                        local dot2D = (forward2D.x * vel2D.x + forward2D.y * vel2D.y) / (lenF * lenV)
                        -- If angle between motion and heading is more than ~18 degrees (dot < 0.95), it's sliding
                        isSliding = speed > 3.0 and math.abs(dot2D) < 0.95
                    end

                    if DoesEntityExist(driver) then
                        if isBurnout then
                            TaskVehicleTempAction(driver, veh, 30, 1) -- Burnout action
                        elseif isSliding then
                            TaskVehicleTempAction(driver, veh, 6, 1) -- Force handbrake to trigger screeching sounds & smoke during drifts
                        elseif fa.brake and fa.brake > 0.1 then
                            TaskVehicleTempAction(driver, veh, 6, 1) -- Strong brake (forces wheel slip for skid marks and suspension dive)
                        elseif fa.throttle and fa.throttle > 0.1 then
                            TaskVehicleTempAction(driver, veh, 23, 1) -- Accelerate fast (forces suspension squat)
                        else
                            TaskVehicleTempAction(driver, veh, 1, 1) -- Coast/stop
                        end
                    end
                end

                -- Steering wheel visual
                local steer = Utils.Lerp(fa.steer or 0, fb.steer or 0, t)
                SetVehicleSteeringAngle(veh, steer)

                -- Engine sound and RPM
                local rpm = Utils.Lerp(fa.rpm or 0.0, fb.rpm or 0.0, t)
                SetVehicleCurrentRpm(veh, rpm)
                SetVehicleEngineOn(veh, true, true, false)

                -- Lights & Brake lights
                local isBraking = fa.brake and fa.brake > 0.1
                SetVehicleBrakeLights(veh, isBraking)
                if fa.lowBeams then SetVehicleLights(veh, 3) else SetVehicleLights(veh, 4) end

                -- Indicators set
                local indicatorState = fa.indicators or 0
                if indicatorState == 1 then
                    SetVehicleIndicatorLights(veh, 1, true)
                    SetVehicleIndicatorLights(veh, 0, false)
                elseif indicatorState == 2 then
                    SetVehicleIndicatorLights(veh, 1, false)
                    SetVehicleIndicatorLights(veh, 0, true)
                elseif indicatorState == 3 then
                    SetVehicleIndicatorLights(veh, 1, true)
                    SetVehicleIndicatorLights(veh, 0, true)
                else
                    SetVehicleIndicatorLights(veh, 1, false)
                    SetVehicleIndicatorLights(veh, 0, false)
                end

                -- Sirens
                if fa.siren ~= nil then
                    SetVehicleSiren(veh, fa.siren)
                end

                -- Driver Animations
                if DoesEntityExist(driver) and not ghostState.paused then
                    if fa.anim and fa.anim.dict and fa.anim.name then
                        if not IsEntityPlayingAnim(driver, fa.anim.dict, fa.anim.name, 3) then
                            RequestAnimDict(fa.anim.dict)
                            if HasAnimDictLoaded(fa.anim.dict) then
                                TaskPlayAnim(driver, fa.anim.dict, fa.anim.name, 8.0, -8.0, -1, 49, 0, false, false, false)
                            end
                        end
                    else
                        if IsEntityPlayingAnim(driver, "amb@world_human_smoking@male@male_a@idle_a", "idle_a", 3) or 
                           IsEntityPlayingAnim(driver, "cellphone@", "cellphone_text_read_base", 3) or
                           IsEntityPlayingAnim(driver, "cellphone@", "cellphone_call_listen_base", 3) then
                            ClearPedTasks(driver)
                        end
                    end
                end
            end

            Wait(0)
        end
    end)
end

function Playback.Stop(replayId)
    if replayId then
        local ghost = Playback.ActiveGhosts[replayId]
        if ghost then
            ghost.active = false
            if ghost.ghostBlip then RemoveBlip(ghost.ghostBlip) end
            if ghost.ghostVeh and DoesEntityExist(ghost.ghostVeh) then DeleteVehicle(ghost.ghostVeh) end
            if ghost.ghostPed and DoesEntityExist(ghost.ghostPed) then DeletePed(ghost.ghostPed) end
            Playback.ActiveGhosts[replayId] = nil
        end
    else
        for id, _ in pairs(Playback.ActiveGhosts) do
            Playback.Stop(id)
        end
        Playback.ActiveGhosts = {}
    end
end

function Playback.TogglePause(replayId)
    local ghost = Playback.ActiveGhosts[replayId]
    if ghost then
        ghost.paused = not ghost.paused
        if ghost.ghostVeh and DoesEntityExist(ghost.ghostVeh) then
            FreezeEntityPosition(ghost.ghostVeh, ghost.paused)
        end
        return ghost.paused
    end
    return nil
end

function Playback.SetSpeed(replayId, speed)
    local ghost = Playback.ActiveGhosts[replayId]
    if ghost then
        ghost.speed = speed
    end
end

function Playback.SetCollision(replayId, collision)
    local ghost = Playback.ActiveGhosts[replayId]
    if ghost then
        ghost.collision = collision
        if ghost.ghostVeh and DoesEntityExist(ghost.ghostVeh) then
            SetEntityCollision(ghost.ghostVeh, true, false)
        end
    end
end

function Playback.IsPlaying(replayId)
    local ghost = Playback.ActiveGhosts[replayId]
    return ghost ~= nil and ghost.active
end

function Playback.IsActive()
    for _, ghost in pairs(Playback.ActiveGhosts) do
        if ghost.active then return true end
    end
    return false
end

function Playback.ResetAllTimes()
    local now = GetGameTimer()
    for _, ghost in pairs(Playback.ActiveGhosts) do
        ghost.startTime = now
        ghost.currentTime = 0
    end
end

function Playback.StartAll(trackName)
    local replays = Storage.Replays[trackName] or {}
    for _, r in ipairs(replays) do
        if not Playback.IsPlaying(r.id) then
            Playback.Start(r)
        end
    end
    Playback.ResetAllTimes()
end

exports('IsGhostEntity', function(entity)
    for _, ghost in pairs(Playback.ActiveGhosts) do
        if ghost.ghostVeh == entity or ghost.ghostPed == entity then
            return true
        end
    end
    return false
end)
