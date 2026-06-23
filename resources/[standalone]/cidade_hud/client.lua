local fomeSede = HudConfig.fomeSede
local exibCombustivel = HudConfig.combustivel
local exibStress = HudConfig.stress
local hudoff = false
local inCar = false
local vehicle = 0
local lastMessages = {}

local function Notify(tipo, mensagem)
    local notifyType = "inform"
    if tipo == "sucesso" then
        notifyType = "success"
    elseif tipo == "negado" or tipo == "erro" or tipo == "fome" or tipo == "sede" then
        notifyType = "error"
    end
    lib.notify({
        title = 'HUD',
        description = mensagem,
        type = notifyType,
    })
end

local function sendChanged(key, message)
    local encoded = json.encode(message)
    if lastMessages[key] == encoded then return end
    lastMessages[key] = encoded
    SendNUIMessage(message)
end

local function clamp(value)
    return math.max(0, math.min(100, math.floor(tonumber(value) or 0)))
end

local function getHunger()
    return clamp(LocalPlayer.state.hunger or 100)
end

local function getThirst()
    return clamp(LocalPlayer.state.thirst or 100)
end

local function getStress()
    return clamp(LocalPlayer.state.stress or 0)
end

local function getPlayerIdentity()
    local qbxPlayer = exports.qbx_core:GetPlayerData() or {}
    local charinfo = qbxPlayer.charinfo or {}
    local firstName = charinfo.firstname or ""
    local lastName = charinfo.lastname or ""
    local fullName = ("%s %s"):format(firstName, lastName):gsub("^%s*(.-)%s*$", "%1")

    return {
        playerName = fullName ~= "" and fullName or GetPlayerName(PlayerId()),
        passport = qbxPlayer.citizenid or tostring(GetPlayerServerId(PlayerId())),
    }
end

local function getClock()
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    local months = {
        "Janeiro", "Fevereiro", "Marco", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    }
    return ("%02d"):format(hour), ("%02d"):format(minute), GetClockDayOfMonth(), months[GetClockMonth() + 1]
end

local function getCommonMessage(action)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    local health = maxHealth > 100 and ((GetEntityHealth(ped) - 100) / (maxHealth - 100)) * 100 or 100
    local hour, minute, day, month = getClock()

    return {
        action = action,
        health = clamp(health),
        armour = clamp(GetPedArmour(ped)),
        stamina = clamp(100 - GetPlayerSprintStaminaRemaining(PlayerId())),
        hunger = getHunger(),
        thirst = getThirst(),
        stress = getStress(),
        street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)),
        hour = hour,
        minute = minute,
        day = day,
        month = month,
        fomeSede = fomeSede,
        exibCombustivel = exibCombustivel,
        exibStress = exibStress,
        inCar = inCar,
    }
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local currentVehicle = GetVehiclePedIsIn(ped, false)
        inCar = currentVehicle ~= 0
        vehicle = currentVehicle
        DisplayRadar(inCar)
        sendChanged("common", getCommonMessage(inCar and "inCar" or "update"))
        Wait(inCar and 500 or 750)
    end
end)

CreateThread(function()
    while true do
        if inCar and DoesEntityExist(vehicle) then
            local speed = math.ceil(GetEntitySpeed(vehicle) * 3.6)
            local gear = GetVehicleCurrentGear(vehicle)
            if speed == 0 then
                gear = "N"
            elseif gear == 0 then
                gear = "R"
            end

            local isElectric = exports.cidade_tycoon_core:IsVehicleElectric(GetEntityModel(vehicle))
            if isElectric and gear ~= "R" and gear ~= "N" then
                gear = "D"
            end

            local vehStatus = nil
            if Entity(vehicle).state['tycoon:status'] then
                vehStatus = Entity(vehicle).state['tycoon:status']
            else
                -- Request initial status if missing
                lib.callback('cidade_tycoon_maintenance:server:getVehicleStatus', false, function(data)
                    if data and data.subsystems then
                        local convertedStatus = {}
                        for _, sub in ipairs(data.subsystems) do
                            if sub.key == 'engine' then
                                convertedStatus.engine_health = sub.health
                            elseif sub.key == 'transmission' then
                                convertedStatus.transmission_health = sub.health
                            elseif sub.key == 'battery' then
                                convertedStatus.battery_health = sub.health
                            elseif sub.key == 'brakes' then
                                convertedStatus.brakes_health = sub.health
                            elseif sub.key == 'suspension' then
                                convertedStatus.suspension_health = sub.health
                            elseif sub.key == 'tire_lf' then
                                convertedStatus.tire_lf_health = sub.health
                            elseif sub.key == 'tire_rf' then
                                convertedStatus.tire_rf_health = sub.health
                            elseif sub.key == 'tire_lr' then
                                convertedStatus.tire_lr_health = sub.health
                            elseif sub.key == 'tire_rr' then
                                convertedStatus.tire_rr_health = sub.health
                            end
                        end
                        Entity(vehicle).state:set('tycoon:status', convertedStatus, true)
                    end
                end, GetVehicleNumberPlateText(vehicle))
            end

            local fuel = GetVehicleFuelLevel(vehicle)
            if DecorExistOn(vehicle, "bzfuel_level") then
                fuel = DecorGetFloat(vehicle, "bzfuel_level")
            end

            if isElectric then
                if vehStatus and vehStatus.battery_charge then
                    fuel = vehStatus.battery_charge  -- battery_charge = nivel de carga atual
                else
                    fuel = 100.0
                end
            end

            -- Calculate average component health for the overall bar indicator
            local avgHealth = 100.0
            if vehStatus then
                local healths = {}
                if isElectric then
                    table.insert(healths, vehStatus.battery_health or 100.0)
                else
                    table.insert(healths, vehStatus.engine_health or 100.0)
                    table.insert(healths, vehStatus.transmission_health or 100.0)
                end
                table.insert(healths, vehStatus.brakes_health or 100.0)
                table.insert(healths, vehStatus.suspension_health or 100.0)
                table.insert(healths, vehStatus.tire_lf_health or (vehStatus.tires_health or 100.0))
                table.insert(healths, vehStatus.tire_rf_health or (vehStatus.tires_health or 100.0))
                table.insert(healths, vehStatus.tire_lr_health or (vehStatus.tires_health or 100.0))
                table.insert(healths, vehStatus.tire_rr_health or (vehStatus.tires_health or 100.0))
                table.insert(healths, vehStatus.body_health or 100.0)
                local sum = 0
                for _, h in ipairs(healths) do sum = sum + h end
                avgHealth = sum / #healths
            end

            sendChanged("vehicle", {
                only = "updateSpeed",
                speed = speed,
                fuel = clamp(fuel),
                gear = gear,
                locked = GetVehicleDoorLockStatus(vehicle),
                cinto = LocalPlayer.state.seatbelt == true,
                exibCombustivel = exibCombustivel,
                inCar = true,
                vehStatus = vehStatus,
                isElectric = isElectric,
                avgHealth = clamp(avgHealth),
            })
            Wait(100)
        else
            lastMessages.vehicle = nil
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        local proximity = LocalPlayer.state.proximity and LocalPlayer.state.proximity.distance or 3.0
        local range = proximity <= 2.0 and 1 or (proximity <= 7.0 and 2 or 3)
        sendChanged("voice", {
            action = "voice",
            number = range,
            falando = NetworkIsPlayerTalking(PlayerId()) or MumbleIsPlayerTalking(PlayerId()) or LocalPlayer.state.talking == true,
        })
        Wait(200)
    end
end)

-- Consolidated stress management thread (driving, shooting, screen effects)
CreateThread(function()
    local tickCount = 0
    while true do
        Wait(250)
        tickCount = tickCount + 1
        local ped = PlayerPedId()

        -- Stress from shooting (every tick, ~4x/sec)
        if IsPedShooting(ped) and math.random() <= 0.1 then
            TriggerServerEvent("hud:server:GainStress", math.random(1, 5))
        end

        -- Stress from high speed & screen blur (every 40 ticks = ~10sec)
        if tickCount % 40 == 0 then
            local currentVehicle = GetVehiclePedIsIn(ped, false)
            if currentVehicle ~= 0 and DoesEntityExist(currentVehicle) and GetEntitySpeed(currentVehicle) * 3.6 >= 90 then
                TriggerServerEvent("hud:server:GainStress", math.random(1, 3))
            end

            if getStress() >= 60 then
                TriggerScreenblurFadeIn(500.0)
                Wait(1000)
                TriggerScreenblurFadeOut(500.0)
            end
        end
    end
end)

-- Passive stress relief thread (interval-based)
CreateThread(function()
    while true do
        Wait(HudConfig.stress_passive_interval or 60000)

        if HudConfig.stress_passive_relief and getStress() > 0 then
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false)
                and not IsPedShooting(ped)
                and not IsPedInMeleeCombat(ped)
                and not IsPedSprinting(ped)
                and not IsPedRunning(ped)
                and not IsPauseMenuActive()
            then
                TriggerServerEvent("hud:server:RelieveStress", HudConfig.stress_passive_amount or 1)
            end
        end
    end
end)

RegisterCommand("relaxar", function()
    if not HudConfig.stress_relax_command then return end

    local ped = PlayerPedId()
    if getStress() <= 0 then
        Notify("sucesso", "Você já está sem stress.")
        return
    end

    if IsPedInAnyVehicle(ped, false) then
        Notify("negado", "Saia do veículo para relaxar.")
        return
    end

    if IsPedShooting(ped) or IsPedInMeleeCombat(ped) or IsPedSprinting(ped) or IsPedRunning(ped) then
        Notify("negado", "Pare em um lugar seguro para relaxar.")
        return
    end

    local duration = HudConfig.stress_relax_duration or 15000
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_YOGA", 0, true)
    SendNUIMessage({
        type = "ui",
        display = true,
        time = duration,
        text = "RELAXANDO"
    })

    Wait(duration)
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    TriggerServerEvent("hud:server:RequestStressRelief", HudConfig.stress_relax_amount or 15)
end, false)

local currentMissionData = nil

RegisterNetEvent('cidade_tycoon_tablet:client:updateFreelanceHUD', function(data)
    currentMissionData = data
    SendNUIMessage({
        action = "updateMission",
        active = data.active,
        cargoHealth = data.cargoHealth or 100,
        totalDelivered = data.totalDelivered or 0,
        totalRequired = data.totalRequired or 1,
        phase = data.phase or data.objective,
        inTrunk = data.inTrunk or 0,
        capacity = data.capacity or 0
    })
end)

RegisterNetEvent('cidade_tycoon_tablet:client:hideFreelanceHUD', function()
    currentMissionData = nil
    SendNUIMessage({
        action = "updateMission",
        active = false
    })
end)

local function updateTycoonUI(profile)
    local identity = getPlayerIdentity()
    if profile then
        SendNUIMessage({
            action = "updateTycoon",
            playerName = identity.playerName,
            passport = identity.passport,
            companyName = profile.companyName or "Logística Tycoon",
            level = profile.level or 1,
            experience = profile.experience or 0,
            maxExperience = (profile.level or 1) * 2000
        })

        if not currentMissionData then
            local mission = profile.activeMission
            if mission then
                SendNUIMessage({
                    action = "updateMission",
                    active = true,
                    cargoHealth = mission.cargoHealth or 100,
                    totalDelivered = mission.totalDelivered or 0,
                    totalRequired = mission.totalRequired or 1,
                    phase = mission.phase or mission.objective,
                    inTrunk = mission.inTrunk or 0,
                    capacity = mission.capacity or 0
                })
            else
                SendNUIMessage({ action = "updateMission", active = false })
            end
        end
    else
        SendNUIMessage({
            action = "updateTycoon",
            playerName = identity.playerName,
            passport = identity.passport,
            level = false
        })
    end
end

-- Reactive State Bag Listener (Zero-Loop Pattern)
AddStateBagChangeHandler('tycoonProfile', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(bagName, key, value, _unused, replicated)
    updateTycoonUI(value)
end)

-- Initial Sync
CreateThread(function()
    Wait(2000)
    updateTycoonUI(LocalPlayer.state.tycoonProfile)
end)

RegisterCommand("cr", function(_, args)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= PlayerPedId() or IsEntityInAir(veh) then return end

    if not args[1] then
        SetEntityMaxSpeed(veh, GetVehicleMaxSpeed(GetEntityModel(veh)))
        Notify("sucesso", "Limitador de velocidade desligado.")
        return
    end

    local targetSpeed = tonumber(args[1])
    if not targetSpeed then return end
    SetEntityMaxSpeed(veh, targetSpeed / 3.6)
    Notify("sucesso", ("Velocidade maxima travada em %d KM/H."):format(targetSpeed))
end)

RegisterNetEvent("hudOff", function(status)
    hudoff = status
    SendNUIMessage({ hudoff = hudoff })
end)

RegisterCommand("hud", function()
    hudoff = not hudoff
    SendNUIMessage({ hudoff = hudoff })
end)

RegisterNetEvent("pma-voice:clSetPlayerRadio", function(channel)
    SendNUIMessage({ action = "connect-radio", freq = channel and channel > 0 and channel or 0 })
end)

AddEventHandler("pma-voice:radioActive", function(active)
    SendNUIMessage({ action = "talking-radio", radio = active })
end)

RegisterNetEvent("progress", function(time, text)
    SendNUIMessage({ type = "ui", display = true, time = time, text = text })
end)
