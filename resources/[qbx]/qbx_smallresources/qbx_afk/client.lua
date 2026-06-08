local timeUntilAFK = 300 -- 5 minutos padrão
local isAFK = false
local lastInputTime = GetGameTimer()
local prevCoords = nil
local animDict = "anim@amb@business@bcm@bcm_spa_p1@"
local animName = "sit_floor_sleep_clip"
local isFrozen = false
local combatCooldownUntil = 0

-- Carregar configuração do recurso se disponível
local configRaw = LoadResourceFile(GetCurrentResourceName(), "qbx_afk/config.json")
if configRaw then
    local config = json.decode(configRaw)
    if config then
        if config.timeUntilAFK then
            timeUntilAFK = config.timeUntilAFK
        elseif config.timeUntilAFKKick then
            timeUntilAFK = math.max(60, math.floor(config.timeUntilAFKKick / 3))
        end
    end
end

-- Função para ativar/desativar modo pacífico (fantasma + invencível)
local function togglePassiveMode(state)
    local ped = PlayerPedId()
    if state then
        SetEntityAlpha(ped, 100, false) -- Fica transparente
        SetEntityInvincible(ped, true) -- Fica invencível
        SetBlockingOfNonTemporaryEvents(ped, true) -- Não reage a nada ao redor
        exports.qbx_core:Notify('Modo Pacífico Ativo (AFK)', 'inform', 5000)
    else
        ResetEntityAlpha(ped)
        SetEntityInvincible(ped, false)
        SetBlockingOfNonTemporaryEvents(ped, false)
        
        -- Inicia trava de combate de 2 minutos
        combatCooldownUntil = GetGameTimer() + (120000)
        exports.qbx_core:Notify('Retornando... Combate bloqueado por 2 minutos para evitar abusos.', 'warning', 10000)
    end
end

-- Função para limpar o estado e animação
local function clearSittingAnim(ped)
    if isFrozen then
        FreezeEntityPosition(ped, false)
        isFrozen = false
    end
    ClearPedTasksImmediately(ped)
end

-- Função para reproduzir a animação
local function playSittingAnim(ped)
    ClearPedTasksImmediately(ped)
    RequestAnimDict(animDict)
    local timer = 0
    while not HasAnimDictLoaded(animDict) and timer < 100 do
        Wait(10)
        timer = timer + 1
    end
    
    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
    else
        -- Fallback se a animação do casino falhar
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_SIT_UPS", 0, true)
    end
    
    -- Congelar a posição do ped após ele sentar
    CreateThread(function()
        Wait(2000)
        if isAFK and not IsPedInAnyVehicle(ped, false) then
            FreezeEntityPosition(ped, true)
            isFrozen = true
        end
    end)
end

-- Thread de detecção de AFK
CreateThread(function()
    local lastCheck = GetGameTimer()
    local hasNotifiedRestore = true
    
    while true do
        InvalidateIdleCam()
        InvalidateVehicleIdleCam()
        
        local ped = PlayerPedId()
        
        if LocalPlayer.state.isLoggedIn then
            if IsEntityDead(ped) then
                if isAFK then
                    isAFK = false
                    TriggerServerEvent('qbx_afk:server:setAFK', false)
                    clearSittingAnim(ped)
                    togglePassiveMode(false)
                    combatCooldownUntil = 0
                end
            else
                local coords = GetEntityCoords(ped)
                local hasInput = false
                
                -- Checagem de Input
                if GetDisabledControlNormal(0, 1) ~= 0.0 or GetDisabledControlNormal(0, 2) ~= 0.0 then
                    hasInput = true
                end

                if not hasInput then
                    for i = 30, 36 do 
                        if IsControlPressed(0, i) or IsDisabledControlPressed(0, i) then
                            hasInput = true
                            break
                        end
                    end
                end

                if not hasInput then
                    local commonControls = {18, 22, 23, 24, 25, 37, 38, 44, 140, 141, 142}
                    for _, controlId in ipairs(commonControls) do
                        if IsControlPressed(0, controlId) or IsDisabledControlPressed(0, controlId) then
                            hasInput = true
                            break
                        end
                    end
                end
                
                if IsNuiFocused() then hasInput = true end
                if not isFrozen and prevCoords and #(prevCoords - coords) > 0.5 then hasInput = true end
                
                if hasInput then
                    lastInputTime = GetGameTimer()
                    prevCoords = coords
                    
                    if isAFK then
                        isAFK = false
                        TriggerServerEvent('qbx_afk:server:setAFK', false)
                        clearSittingAnim(ped)
                        togglePassiveMode(false)
                        hasNotifiedRestore = false
                    end
                end
                
                local now = GetGameTimer()
                if now - lastCheck >= 1000 then
                    lastCheck = now
                    if not hasInput then
                        local idleTime = (now - lastInputTime) / 1000
                        if idleTime >= timeUntilAFK and not isAFK then
                            isAFK = true
                            TriggerServerEvent('qbx_afk:server:setAFK', true)
                            togglePassiveMode(true)
                            if not IsPedInAnyVehicle(ped, false) and not IsPedFalling(ped) and not IsPedSwimming(ped) then
                                playSittingAnim(ped)
                            end
                        end
                        if isAFK and not IsPedInAnyVehicle(ped, false) and not IsPedFalling(ped) and not IsPedSwimming(ped) and not IsEntityPlayingAnim(ped, animDict, animName, 3) and not IsPedUsingAnyScenario(ped) then
                            playSittingAnim(ped)
                        end
                    end
                end
            end
        else
            Wait(1000)
        end
        
        -- BLOQUEIO DE COMBATE
        local nowTimer = GetGameTimer()
        if isAFK or nowTimer < combatCooldownUntil then
            if not isAFK and nowTimer < combatCooldownUntil then
                DrawText3D(GetEntityCoords(ped) + vector3(0.0, 0.0, 1.1), "~r~RECARREGANDO COMBATE")
            end

            DisablePlayerFiring(PlayerId(), true) 
            SetPlayerCanDoDriveBy(PlayerId(), false)
            
            -- Bloqueio Extensivo de Controles de Ataque
            local controlsToBlock = {24, 25, 37, 44, 45, 47, 58, 69, 70, 92, 114, 140, 141, 142, 143, 257, 263, 264, 331}
            for _, control in ipairs(controlsToBlock) do
                DisableControlAction(0, control, true)
                DisableControlAction(1, control, true)
                DisableControlAction(2, control, true)
            end
            
            if IsPedInMeleeCombat(ped) or IsPedPerformingMeleeAction(ped) then
                ClearPedTasksImmediately(ped)
            end
        elseif not hasNotifiedRestore then
            hasNotifiedRestore = true
            exports.qbx_core:Notify('Habilidades de combate restauradas.', 'success', 5000)
        end
        
        Wait(0)
    end
end)

-- Função para desenhar o texto 3D
function DrawText3D(coords, text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 50, 50, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Texto AFK sobre a cabeça
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
                if playerPed == myPed then isPlayerAFK = isAFK
                else local s = Player(serverId).state isPlayerAFK = s and s.isAFK end
                if isPlayerAFK then
                    local targetCoords = GetEntityCoords(playerPed)
                    if #(myCoords - targetCoords) < 15.0 then
                        sleep = 0
                        DrawText3D(targetCoords + vector3(0.0, 0.0, 1.1), "AFK")
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Comando /afk corrigido
RegisterCommand('afk', function()
    if not isAFK then
        isAFK = true
        TriggerServerEvent('qbx_afk:server:setAFK', true)
        togglePassiveMode(true)
        playSittingAnim(PlayerPedId())
    else
        isAFK = false
        TriggerServerEvent('qbx_afk:server:setAFK', false)
        clearSittingAnim(PlayerPedId())
        togglePassiveMode(false)
    end
end)