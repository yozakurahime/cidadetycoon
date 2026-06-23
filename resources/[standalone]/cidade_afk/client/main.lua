-- client/main.lua
-- AFK Detection with IN/OUT vehicle differentiation

local Config = require 'shared.config'
local afkConfig = Config.AFK

-- State
local isAFK = false
local isImmune = false
local lastInputTime = GetGameTimer()
local lastCoords = nil
local idleSeconds = 0
local hasNotifiedAFK = false
local hasNotifiedWarning = false
local hasNotifiedKickWarning = false
local combatCooldownUntil = 0
local vehicleStoppedSince = 0
local afkAnimDict = "anim@amb@business@bcm@bcm_spa_p1@"
local afkAnimName = "sit_floor_sleep_clip"

-- ===================== HELPERS =====================

local function notify(msg, type, duration)
    lib.notify({ title = 'AFK', description = msg, type = type or 'inform', duration = duration or 5000 })
end

local function isInVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    return veh ~= 0
end

local function getVehicleSpeed()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return -1 end
    return GetEntitySpeed(veh) -- m/s
end

local function IsPlayerInCombat()
    local ped = PlayerPedId()
    return IsPedInMeleeCombat(ped) or IsPedPerformingMeleeAction(ped) or
           IsPedArmed(ped, 7) or GetPedAlertness(ped) > 0.5 or
           IsPedShooting(ped) or IsPedBeingStunned(ped)
end

-- ===================== PASSIVE MODE =====================

local function togglePassiveMode(state)
    local ped = PlayerPedId()
    if state then
        SetEntityAlpha(ped, 100, false)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        notify('Modo Pasivo Ativado (AFK)', 'inform', 3000)
    else
        ResetEntityAlpha(ped)
        SetEntityInvincible(ped, false)
        SetBlockingOfNonTemporaryEvents(ped, false)
        combatCooldownUntil = GetGameTimer() + (afkConfig.combatCooldown * 1000)
        notify('Retornando... Combate bloqueado por ' .. afkConfig.combatCooldown .. 's para evitar abusos.', 'warning', 8000)
    end
end

-- ===================== ANIMATIONS =====================

local function clearAFKAnim()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)
end

local function playSitAnim()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsPedFalling(ped) or IsPedSwimming(ped) then return end

    ClearPedTasksImmediately(ped)
    RequestAnimDict(afkAnimDict)
    local timer = 0
    while not HasAnimDictLoaded(afkAnimDict) and timer < 100 do
        Wait(10)
        timer = timer + 1
    end

    if HasAnimDictLoaded(afkAnimDict) then
        TaskPlayAnim(ped, afkAnimDict, afkAnimName, 8.0, -8.0, -1, 1, 0, false, false, false)
    else
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_SIT_UPS", 0, true)
    end

    CreateThread(function()
        Wait(2000)
        if isAFK and not IsPedInAnyVehicle(ped, false) then
            FreezeEntityPosition(ped, true)
        end
    end)
end

-- ===================== VEHICLE AFK HANDLING =====================

local function applyVehicleAFK()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end

    -- Turn on hazards
    SetVehicleIndicatorLights(veh, 1, true) -- left
    SetVehicleIndicatorLights(veh, 0, true) -- right
    SetVehicleHazardLights(veh, true)

    -- Apply passive in vehicle
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    notify('AFK no veiculo - pisca-alerta ligado. Retorne ao volante!', 'warning', 5000)
end

local function clearVehicleAFK()
    local ped = PlayerPedId()
    SetEntityInvincible(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, false)
    combatCooldownUntil = GetGameTimer() + (afkConfig.combatCooldown * 1000)

    -- Turn off hazards
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        SetVehicleIndicatorLights(veh, 1, false)
        SetVehicleIndicatorLights(veh, 0, false)
        SetVehicleHazardLights(veh, false)
    end

    notify('Bem-vindo de volta! Controles de combate bloqueados por ' .. afkConfig.combatCooldown .. 's.', 'warning', 8000)
end

-- ===================== INPUT DETECTION =====================

local function hasActiveInput()
    local ped = PlayerPedId()

    -- Movement keys (WASD)
    if GetControlNormal(0, 32) ~= 0.0 or GetControlNormal(0, 33) ~= 0.0 or
       GetControlNormal(0, 34) ~= 0.0 or GetControlNormal(0, 35) ~= 0.0 then
        return true
    end

    -- Mouse movement
    if GetDisabledControlNormal(0, 1) ~= 0.0 or GetDisabledControlNormal(0, 2) ~= 0.0 then
        return true
    end

    -- Common interaction controls
    for _, ctrlId in ipairs(Config.ActiveControls) do
        if IsControlPressed(0, ctrlId) or IsDisabledControlPressed(0, ctrlId) then
            return true
        end
    end

    -- NUI focus (typing in menus)
    if IsNuiFocused() then return true end

    -- Movement (walking around without keys, e.g., using mouse for vehicle)
    local coords = GetEntityCoords(ped)
    if lastCoords and #(lastCoords - coords) > 2.0 then return true end
    lastCoords = coords

    return false
end

-- ===================== DRAW AFK INDICATOR =====================

local function drawText3D(coords, text, color)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(color[1], color[2], color[3], 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- ===================== MAIN AFK THREAD =====================

CreateThread(function()
    while true do
        Wait(afkConfig.checkInterval)

        local ped = PlayerPedId()

        -- Only check when logged in
        if not LocalPlayer.state.isLoggedIn then
            Wait(2000)
            if isAFK then
                isAFK = false
                clearAFKAnim()
                togglePassiveMode(false)
                clearVehicleAFK()
                TriggerServerEvent('cidade_afk:server:resetAFK')
            end
            return
        end

        -- Dead players shouldn't be AFK
        if IsEntityDead(ped) then
            if isAFK then
                isAFK = false
                clearAFKAnim()
                togglePassiveMode(false)
                clearVehicleAFK()
                TriggerServerEvent('cidade_afk:server:resetAFK')
            end
            goto continue
        end

        -- Check input
        local gotInput = hasActiveInput()

        -- In-vehicle: check if vehicle is stopped
        local inVehicle = isInVehicle()
        local speed = getVehicleSpeed()

        if gotInput then
            -- RESET: Player is active
            lastInputTime = GetGameTimer()
            idleSeconds = 0
            hasNotifiedWarning = false
            hasNotifiedAFK = false
            hasNotifiedKickWarning = false
            vehicleStoppedSince = 0

            if isAFK then
                isAFK = false
                if inVehicle then
                    clearVehicleAFK()
                    TriggerServerEvent('cidade_afk:server:resetAFK')
                else
                    clearAFKAnim()
                    togglePassiveMode(false)
                    TriggerServerEvent('cidade_afk:server:resetAFK')
                end
            end
        else
            -- IDLE: Calculate idle time
            idleSeconds = (GetGameTimer() - lastInputTime) / 1000

            -- For vehicle AFK, also require the vehicle to be stopped
            if inVehicle then
                if speed > 1.0 then
                    -- Vehicle is moving - reset everything
                    lastInputTime = GetGameTimer()
                    idleSeconds = 0
                    vehicleStoppedSince = 0
                    hasNotifiedWarning = false
                    hasNotifiedAFK = false

                    if isAFK then
                        isAFK = false
                        clearVehicleAFK()
                        TriggerServerEvent('cidade_afk:server:resetAFK')
                    end
                    goto continue
                else
                    -- Vehicle is stopped, track how long
                    if vehicleStoppedSince == 0 then
                        vehicleStoppedSince = GetGameTimer()
                    end
                    -- Only count idle time if vehicle has been stopped long enough
                    local stoppedFor = (GetGameTimer() - vehicleStoppedSince) / 1000
                    if stoppedFor < afkConfig.vehicleStopSeconds then
                        -- Vehicle just stopped, don't trigger AFK yet
                        -- But still reset if they were AFK
                        if isAFK then
                            isAFK = false
                            clearVehicleAFK()
                            TriggerServerEvent('cidade_afk:server:resetAFK')
                        end
                        goto continue
                    end
                end
            end

            -- WARNING: X minutes idle
            if idleSeconds >= afkConfig.warningTime and not hasNotifiedWarning then
                hasNotifiedWarning = true
                local minsLeft = math.floor((afkConfig.afkTime - afkConfig.warningTime) / 60)
                if inVehicle then
                    notify('Veiculo parado ha ' .. math.floor(idleSeconds / 60) .. 'min. Modo AFK em ' .. minsLeft .. 'min.', 'warning', 8000)
                else
                    notify('Inativo ha ' .. math.floor(idleSeconds / 60) .. 'min. Modo AFK em ' .. minsLeft .. 'min.', 'warning', 8000)
                end
            end

            -- AFK MODE: Activate
            if idleSeconds >= afkConfig.afkTime and not isAFK and not IsPlayerInCombat() then
                isAFK = true
                TriggerServerEvent('qbx_afk:server:setAFK', true)

                if inVehicle then
                    applyVehicleAFK()
                else
                    togglePassiveMode(true)
                    playSitAnim()
                end

                notify('Modo AFK ativado.', 'inform', 3000)
            end

            -- KICK: Check with server
            if idleSeconds >= afkConfig.warningTime then
                local serverResult = lib.callback.await('cidade_afk:server:checkAFK', false,
                    idleSeconds, inVehicle, 0)

                if serverResult and serverResult.ignore then
                    isImmune = true
                    -- Don't check for kick if immune
                elseif serverResult and serverResult.warnKick and not hasNotifiedKickWarning then
                    hasNotifiedKickWarning = true
                    notify('ATENCAO: Voce sera desconectado em ' .. (serverResult.secondsUntilKick or 60) .. 's por inatividade!', 'error', 10000)
                end
            end
        end

        ::continue::
    end
end)

-- ===================== DRAW AFK LABELS =====================

CreateThread(function()
    while true do
        local sleep = 1000
        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)
        local activePlayers = GetActivePlayers()

        for i = 1, #activePlayers do
            local player = activePlayers[i]
            local playerPed = GetPlayerPed(player)
            if DoesEntityExist(playerPed) then
                local serverId = GetPlayerServerId(player)
                local isPlayerAFK = false
                if playerPed == myPed then
                    isPlayerAFK = isAFK
                else
                    local state = Player(serverId).state
                    isPlayerAFK = state and state.isAFK or false
                end

                if isPlayerAFK then
                    local targetCoords = GetEntityCoords(playerPed)
                    if #(myCoords - targetCoords) < 15.0 then
                        sleep = 0
                        local inVeh = IsPedInAnyVehicle(playerPed, false)
                        local label = inVeh and "💤 AFK (Veiculo)" or "💤 AFK"
                        drawText3D(targetCoords + vector3(0.0, 0.0, 1.4), label, { 255, 200, 50 })
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ===================== COMBAT BLOCK ON RETURN =====================

CreateThread(function()
    while true do
        Wait(0)
        local now = GetGameTimer()

        -- Block combat during AFK or cooldown
        if isAFK or now < combatCooldownUntil then
            if isAFK then
                -- Full block during AFK
                DisablePlayerFiring(PlayerId(), true)
                SetPlayerCanDoDriveBy(PlayerId(), false)
                local controls = {24, 25, 37, 44, 45, 47, 58, 69, 70, 92, 114, 140, 141, 142, 143, 257, 263, 264, 331}
                for _, ctrl in ipairs(controls) do
                    DisableControlAction(0, ctrl, true)
                    DisableControlAction(1, ctrl, true)
                    DisableControlAction(2, ctrl, true)
                end
            elseif now < combatCooldownUntil then
                -- Cooldown: show timer
                local cooldownLeft = math.ceil((combatCooldownUntil - now) / 1000)
                drawText3D(GetEntityCoords(PlayerPedId()) + vector3(0.0, 0.0, 1.1),
                    "🔒 RECARREGANDO: " .. cooldownLeft .. "s", { 255, 50, 50 })

                DisablePlayerFiring(PlayerId(), true)
                SetPlayerCanDoDriveBy(PlayerId(), false)
                local controls = {24, 25, 37, 44, 140, 141, 142, 257, 263, 264}
                for _, ctrl in ipairs(controls) do
                    DisableControlAction(0, ctrl, true)
                end
            end
        end
    end
end)

-- ===================== SAFETY: CANCEL AFK ON DAMAGE =====================

-- If someone damages an AFK player, auto-restore
CreateThread(function()
    while true do
        Wait(100)
        if isAFK and IsPedInMeleeCombat(PlayerPedId()) then
            isAFK = false
            clearAFKAnim()
            togglePassiveMode(false)
            clearVehicleAFK()
            TriggerServerEvent('cidade_afk:server:resetAFK')
            TriggerServerEvent('qbx_afk:server:setAFK', false)
            notify('AFK cancelado - voce esta em combate!', 'error', 5000)
        end
    end
end)
