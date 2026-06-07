local fomeSede = config_fomeSede
local exibCombustivel = config_combustivel
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
    exports.qbx_core:Notify(mensagem, notifyType)
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
    local playerData = exports.qbx_core:GetPlayerData() or {}
    local charinfo = playerData.charinfo or {}
    local firstName = charinfo.firstname or ""
    local lastName = charinfo.lastname or ""
    local fullName = ("%s %s"):format(firstName, lastName):gsub("^%s*(.-)%s*$", "%1")

    return {
        playerName = fullName ~= "" and fullName or GetPlayerName(PlayerId()),
        passport = playerData.citizenid or tostring(GetPlayerServerId(PlayerId())),
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

            local fuel = GetVehicleFuelLevel(vehicle)
            if DecorExistOn(vehicle, "bzfuel_level") then
                fuel = DecorGetFloat(vehicle, "bzfuel_level")
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

CreateThread(function()
    while true do
        if inCar and DoesEntityExist(vehicle) and GetEntitySpeed(vehicle) * 3.6 >= 90 then
            TriggerServerEvent("hud:server:GainStress", math.random(1, 3))
        end
        Wait(10000)
    end
end)

CreateThread(function()
    while true do
        if IsPedShooting(PlayerPedId()) and math.random() <= 0.1 then
            TriggerServerEvent("hud:server:GainStress", math.random(1, 5))
        end
        Wait(250)
    end
end)

CreateThread(function()
    while true do
        if getStress() >= 60 then
            TriggerScreenblurFadeIn(500.0)
            Wait(1000)
            TriggerScreenblurFadeOut(500.0)
        end
        Wait(15000)
    end
end)

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
