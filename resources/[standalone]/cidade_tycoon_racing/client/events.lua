local EventClientState = {
    isActive = false,
    eventId = nil,
    checkpoint = nil,
    deliveryRadius = 10.0,
    checkpointBlip = 0,
    isPromptVisible = false,
    nextDeliveryAttemptAt = 0,
}

local function hidePromptIfVisible()
    if EventClientState.isPromptVisible then
        lib.hideTextUI()
        EventClientState.isPromptVisible = false
    end
end

local function removeCheckpointBlip()
    if EventClientState.checkpointBlip and EventClientState.checkpointBlip ~= 0 and DoesBlipExist(EventClientState.checkpointBlip) then
        RemoveBlip(EventClientState.checkpointBlip)
    end
    EventClientState.checkpointBlip = 0
end

local function cleanupEventState()
    hidePromptIfVisible()
    removeCheckpointBlip()
    ClearAllBlipRoutes()

    EventClientState.isActive = false
    EventClientState.eventId = nil
    EventClientState.checkpoint = nil
    EventClientState.deliveryRadius = 10.0
    EventClientState.nextDeliveryAttemptAt = 0
end

local function createCheckpointBlip(checkpoint)
    removeCheckpointBlip()

    local blipHandle = AddBlipForCoord(checkpoint.x, checkpoint.y, checkpoint.z)
    SetBlipSprite(blipHandle, 67)
    SetBlipScale(blipHandle, 1.0)
    SetBlipColour(blipHandle, 2)
    SetBlipAsShortRange(blipHandle, false)
    SetBlipRoute(blipHandle, true)
    SetBlipRouteColour(blipHandle, 2)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Carga de Alta Prioridade')
    EndTextCommandSetBlipName(blipHandle)

    EventClientState.checkpointBlip = blipHandle
end

RegisterNetEvent('cidade_tycoon_racing:client:startGlobalEvent', function(payload)
    if not payload or not payload.eventId or not payload.checkpoint then return end

    cleanupEventState()

    EventClientState.isActive = true
    EventClientState.eventId = payload.eventId
    EventClientState.checkpoint = payload.checkpoint
    EventClientState.deliveryRadius = payload.deliveryRadius or 10.0

    createCheckpointBlip(EventClientState.checkpoint)
    lib.notify({
        title = 'Evento Global Tycoon',
        description = 'Carga de Alta Prioridade disponível! Siga o GPS.',
        type = 'success'
    })
end)

RegisterNetEvent('cidade_tycoon_racing:client:stopGlobalEvent', function(payload)
    local winnerSource = payload and payload.winnerSource or nil
    local winnerName = payload and payload.winnerName or nil

    if winnerSource then
        if winnerSource == GetPlayerServerId(PlayerId()) then
            local rewardValue = payload.winnerReward or 0
            lib.notify({ title = 'Vitória!', description = ('Você venceu a corrida global e recebeu $%d!'):format(rewardValue), type = 'success' })
        else
            lib.notify({ title = 'Fim de Evento', description = ('Vencedor: %s'):format(winnerName or 'Desconhecido'), type = 'inform' })
        end
    end

    cleanupEventState()
end)

local function updateEventHUD(dist)
    if not EventClientState.isActive then 
        lib.hideTextUI()
        return 
    end

    local rewardValue = EventSystemConfiguration.baseBonusReward
    local statusText = string.format("**CARGA DE ALTA PRIORIDADE**\nDistância: %.0fm\nRecompensa Base: $%d", dist, rewardValue)
    
    lib.showTextUI(statusText, {
        position = "right-center",
        icon = 'truck-fast',
        style = {
            borderRadius = 4,
            backgroundColor = '#131313',
            color = '#6df28f'
        }
    })
end

CreateThread(function()
    while true do
        local waitMilliseconds = 1000

        if EventClientState.isActive and EventClientState.checkpoint then
            local playerPed = PlayerPedId()
            local playerCoordinates = GetEntityCoords(playerPed)
            local dist = #(playerCoordinates - EventClientState.checkpoint)

            updateEventHUD(dist)

            if dist < 150.0 then
                waitMilliseconds = 0
                if dist < EventClientState.deliveryRadius then
                    DrawMarker(1, EventClientState.checkpoint.x, EventClientState.checkpoint.y, EventClientState.checkpoint.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.5, 2.5, 1.0, 50, 220, 90, 140, false, true, 2, false, nil, nil, false)

                    if not EventClientState.isPromptVisible then
                        lib.showTextUI('Pressione [E] para entregar a Carga de Alta Prioridade', { position = "right-center" })
                        EventClientState.isPromptVisible = true
                    end

                    if IsControlJustPressed(0, 38) then
                        local now = GetGameTimer()
                        if now >= EventClientState.nextDeliveryAttemptAt then
                            EventClientState.nextDeliveryAttemptAt = now + 1200
                            TriggerServerEvent('cidade_tycoon_racing:server:attemptPriorityDelivery', EventClientState.eventId)
                        end
                    end
                else
                    hidePromptIfVisible()
                end
            else
                waitMilliseconds = 500
                hidePromptIfVisible()
            end
        else
            hidePromptIfVisible()
        end

        Wait(waitMilliseconds)
    end
end)
