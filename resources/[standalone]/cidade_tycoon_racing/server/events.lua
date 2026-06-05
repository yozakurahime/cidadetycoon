local EventSystemConfiguration = {
    triggerIntervalMilliseconds = 30 * 60 * 1000,
    deliveryRadiusMeters = 10.0,
    maxStraightLineSpeedMetersPerSecond = 95.0,
    antiTeleportGraceMilliseconds = 3000,
    baseBonusReward = 55000,
    bonusPerCompetitor = 8000,
    baseCityTaxPercent = 12,
    priorityRewardExperience = 900,
    checkpoints = {
        vec3(1214.85, -1262.31, 35.23),
        vec3(-716.41, -915.55, 19.22),
        vec3(2681.84, 3290.42, 55.25),
        vec3(1702.93, 4920.61, 42.06),
        vec3(-42.01, -1749.23, 29.42),
        vec3(379.43, 323.43, 103.56),
    }
}

local GlobalEventState = {
    isActive = false,
    eventId = 0,
    checkpoint = nil,
    startedAtMilliseconds = 0,
    participantsBySource = {},
    winnerSource = nil,
}

local function DebugLog(text, ...)
    print(string.format("^3[Tycoon:Server:Events]^7 %s", string.format(text, ...)))
end

local function triggerGlobalEvent()
    if GlobalEventState.isActive then return end

    local checkpointIndex = math.random(#EventSystemConfiguration.checkpoints)
    local selectedCheckpoint = EventSystemConfiguration.checkpoints[checkpointIndex]

    GlobalEventState.eventId = GlobalEventState.eventId + 1
    GlobalEventState.isActive = true
    GlobalEventState.checkpoint = selectedCheckpoint
    GlobalEventState.startedAtMilliseconds = GetGameTimer()
    GlobalEventState.participantsBySource = {}
    GlobalEventState.winnerSource = nil

    TriggerClientEvent('cidade_tycoon_racing:client:startGlobalEvent', -1, {
        eventId = GlobalEventState.eventId,
        checkpoint = selectedCheckpoint,
        deliveryRadius = EventSystemConfiguration.deliveryRadiusMeters
    })

    DebugLog("Evento global #%d iniciado no checkpoint #%d", GlobalEventState.eventId, checkpointIndex)
end

RegisterNetEvent('cidade_tycoon_racing:server:attemptPriorityDelivery', function(eventId)
    local src = source
    if not GlobalEventState.isActive or GlobalEventState.eventId ~= eventId then
        return
    end

    if GlobalEventState.winnerSource then return end

    -- Validation
    local playerPed = GetPlayerPed(src)
    local coords = GetEntityCoords(playerPed)
    local dist = #(coords - GlobalEventState.checkpoint)

    if dist > (EventSystemConfiguration.deliveryRadiusMeters + 5.0) then
        return -- Too far
    end

    -- Winner logic
    GlobalEventState.winnerSource = src
    GlobalEventState.isActive = false

    local reward = EventSystemConfiguration.baseBonusReward
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    
    if player then
        player.Functions.AddMoney('bank', reward, 'tycoon-priority-delivery-win')
        exports.cidade_tycoon_core:LogTransaction(src, reward, 'income', 'event', 'Vitoria em Evento Global: Carga Prioritaria')
        exports.cidade_tycoon_core:AddExperience(src, EventSystemConfiguration.priorityRewardExperience)
    end

    TriggerClientEvent('cidade_tycoon_racing:client:stopGlobalEvent', -1, {
        winnerSource = src,
        winnerName = GetPlayerName(src),
        winnerReward = reward
    })

    DebugLog("Evento global #%d vencido por %s", eventId, GetPlayerName(src))
end)

-- Main Event Loop
CreateThread(function()
    while true do
        Wait(EventSystemConfiguration.triggerIntervalMilliseconds)
        triggerGlobalEvent()
    end
end)
