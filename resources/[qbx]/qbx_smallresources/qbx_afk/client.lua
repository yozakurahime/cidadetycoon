local timeUntilAFK = 300 -- 5 minutos padrão
local isAFK = false
local lastInputTime = GetGameTimer()
local prevCoords = nil
local prevHeading = nil
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
            -- Define o tempo de AFK como 1/3 do tempo de kick (com mínimo de 60 segundos)
            timeUntilAFK = math.max(60, math.floor(config.timeUntilAFKKick / 3))
        end
    end
end

-- Função para ativar/desativar modo pacífico (fantasma + invencível)
local function togglePassiveMode(state)
    local ped = PlayerPedId()
    if state then
        SetEntityAlpha(ped, 150, false) -- Fica transparente (fantasminha)
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
    ClearPedTasks(ped)
end

-- Função para reproduzir a animação
local function playSittingAnim(ped)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end
    
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Congelar a posição do ped após ele sentar (esperar 1 segundo para o ped se posicionar no chão)
    CreateThread(function()
        Wait(1000)
        -- Só congela se o jogador ainda estiver AFK e não estiver em veículo
        if isAFK and not IsPedInAnyVehicle(ped, false) then
            FreezeEntityPosition(ped, true)
            isFrozen = true
        end
    end)
end

-- Thread de detecção de AFK de Alta Performance e Frame Rate Correto
CreateThread(function()
    local lastCheck = GetGameTimer()
    local hasNotifiedRestore = true
    
    while true do
        -- 1. Invalida idle camera nativa a cada frame (Wait 0) para evitar que a câmera mude de perspectiva
        InvalidateIdleCam()
        InvalidateVehicleIdleCam()
        
        local ped = PlayerPedId()
        
        -- Só monitora se o jogador estiver logado
        if LocalPlayer.state.isLoggedIn then
            -- Se o jogador morrer, limpa o estado de AFK imediatamente
            if IsEntityDead(ped) then
                if isAFK then
                    isAFK = false
                    TriggerServerEvent('qbx_afk:server:setAFK', false)
                    clearSittingAnim(ped)
                    togglePassiveMode(false)
                    combatCooldownUntil = 0 -- Reseta cooldown se morrer
                end
            else
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                
                local hasInput = false
                
                -- Checa se qualquer controle principal está sendo ativamente pressionado (movimentação, câmera, etc.)
                for i = 0, 6 do
                    if IsControlPressed(0, i) or IsDisabledControlPressed(0, i) then
                        hasInput = true
                        break
                    end
                end
                
                if not hasInput then
                    for i = 30, 35 do
                        if IsControlPressed(0, i) or IsDisabledControlPressed(0, i) then
                            hasInput = true
                            break
                        end
                    end
                end
                
                if not hasInput then
                    local extraControls = {18, 22, 23, 24, 25, 38, 44}
                    for _, controlId in ipairs(extraControls) do
                        if IsControlPressed(0, controlId) or IsDisabledControlPressed(0, controlId) then
                            hasInput = true
                            break
                        end
                    end
                end
                
                if GetDisabledControlNormal(0, 1) ~= 0.0 or GetDisabledControlNormal(0, 2) ~= 0.0 then
                    hasInput = true
                end
                
                if IsNuiFocused() then
                    hasInput = true
                end
                
                if prevCoords and #(prevCoords - coords) > 0.2 then
                    hasInput = true
                end
                
                -- Se houve ação do jogador, reseta o temporizador e sai do AFK se estiver
                if hasInput then
                    lastInputTime = GetGameTimer()
                    prevCoords = coords
                    prevHeading = heading
                    
                    if isAFK then
                        isAFK = false
                        TriggerServerEvent('qbx_afk:server:setAFK', false)
                        clearSittingAnim(ped)
                        togglePassiveMode(false)
                        hasNotifiedRestore = false
                    end
                end
                
                -- O processamento do timer de inatividade e reinício de animação roda a cada 1000ms para economizar CPU
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
                        
                        -- Se o jogador estiver AFK, mas saiu do veículo ou a animação parou, reinicia a animação
                        if isAFK and not IsPedInAnyVehicle(ped, false) and not IsPedFalling(ped) and not IsPedSwimming(ped) and not IsEntityPlayingAnim(ped, animDict, animName, 3) then
                            playSittingAnim(ped)
                        end
                    end
                end
            end
        else
            Wait(1000)
        end
        
        -- Bloqueia ações de combate se estiver AFK ou na trava de segurança
        local nowTimer = GetGameTimer()
        if isAFK or nowTimer < combatCooldownUntil then
            if not isAFK and nowTimer < combatCooldownUntil then
                -- Desenha aviso de recarga de combate
                DrawText3D(GetEntityCoords(ped) + vector3(0.0, 0.0, 1.1), "~r~RECARREGANDO COMBATE")
            end

            DisablePlayerFiring(PlayerId(), true) -- Desativa tiro
            DisableControlAction(0, 24, true) -- Ataque
            DisableControlAction(0, 25, true) -- Mira
            DisableControlAction(0, 37, true) -- Roda de armas
            DisableControlAction(0, 47, true) -- Arma
            DisableControlAction(0, 58, true) -- Arma
            DisableControlAction(0, 140, true) -- Ataque corporal
            DisableControlAction(0, 141, true) -- Ataque corporal
            DisableControlAction(0, 142, true) -- Ataque corporal
            DisableControlAction(0, 143, true) -- Ataque corporal
            DisableControlAction(0, 263, true) -- Ataque corporal
            DisableControlAction(0, 264, true) -- Ataque corporal
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

-- Thread para renderizar o texto AFK em cima da cabeça
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
                    isPlayerAFK = Player(serverId).state.isAFK
                end
                
                if isPlayerAFK then
                    local targetCoords = GetEntityCoords(playerPed)
                    local dist = #(myCoords - targetCoords)
                    
                    if dist < 15.0 then
                        sleep = 0
                        DrawText3D(targetCoords + vector3(0.0, 0.0, 1.1), "AFK")
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)
