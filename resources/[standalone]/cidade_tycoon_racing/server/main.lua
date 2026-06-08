local function DebugLog(text, ...)
    print(string.format("^1[Tycoon:Server:Racing]^7 %s", string.format(text, ...)))
end
local function createRacingTables()
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_race_winners (
            id INT NOT NULL AUTO_INCREMENT,
            race_id VARCHAR(50) NOT NULL,
            citizenid VARCHAR(50) NOT NULL,
            vehicle_model VARCHAR(50) NOT NULL,
            time_ms INT NOT NULL,
            reward BIGINT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            INDEX (race_id),
            INDEX (citizenid)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local EventSystemConfiguration = {
    triggerIntervalMilliseconds = 30 * 60 * 1000,
    deliveryRadiusMeters = 10.0,
    baseBonusReward = 55000,
    bonusPerCompetitor = 8000,
    baseCityTaxPercent = 12,
    priorityRewardExperience = 900,
    checkpoints = {
        vector3(1214.85, -1262.31, 35.23),
        vector3(-716.41, -915.55, 19.22),
        vector3(2681.84, 3290.42, 55.25),
        vector3(1702.93, 4920.61, 42.06),
        vector3(-42.01, -1749.23, 29.42),
        vector3(379.43, 323.43, 103.56),
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

local function endGlobalPriorityEvent(winnerSource, winnerDisplayName, winnerReward)
    local completedEventId = GlobalEventState.eventId

    for participantSource in pairs(GlobalEventState.participantsBySource) do
        TriggerClientEvent('cidade_tycoon_racing:client:stopGlobalEvent', participantSource, {
            eventId = completedEventId,
            winnerSource = winnerSource,
            winnerName = winnerDisplayName,
            winnerReward = winnerReward,
        })
    end

    if winnerDisplayName then
        TriggerClientEvent('chat:addMessage', -1, {
            template = '<div style="padding: 0.45vw; margin: 0.25vw; background: linear-gradient(90deg, #131313, #1e3f2b); border-left: 4px solid #6df28f; border-radius: 4px;"><strong>[Tycoon Evento Global]</strong> {0} venceu a Carga de Alta Prioridade e recebeu <strong>${1}</strong>.</div>',
            args = { winnerDisplayName, tostring(winnerReward or 0) }
        })
    end

    GlobalEventState.isActive = false
    GlobalEventState.winnerSource = winnerSource
    GlobalEventState.checkpoint = nil
    GlobalEventState.startedAtMilliseconds = 0
    GlobalEventState.participantsBySource = {}
end

local function startGlobalPriorityEvent()
    if GlobalEventState.isActive then return end

    local eligibleParticipants = {}
    local players = GetPlayers()

    for _, srcStr in ipairs(players) do
        local src = tonumber(srcStr)
        local profile = exports.cidade_tycoon_core:GetPlayerProfile(src)
        if profile then
            table.insert(eligibleParticipants, {
                source = src,
                citizenId = profile.citizenid,
                displayName = GetPlayerName(src),
                efficiencyLevel = profile.upgrades.efficiency_tuning or 0
            })
        end
    end

    if #eligibleParticipants == 0 then return end

    GlobalEventState.eventId = GlobalEventState.eventId + 1
    GlobalEventState.isActive = true
    local cpIndex = math.random(1, #EventSystemConfiguration.checkpoints)
    GlobalEventState.checkpoint = EventSystemConfiguration.checkpoints[cpIndex]
    GlobalEventState.startedAtMilliseconds = GetGameTimer()
    GlobalEventState.winnerSource = nil
    GlobalEventState.participantsBySource = {}

    local payload = {
        eventId = GlobalEventState.eventId,
        checkpoint = GlobalEventState.checkpoint,
        deliveryRadius = EventSystemConfiguration.deliveryRadiusMeters,
        startTimestamp = GlobalEventState.startedAtMilliseconds,
    }

    for _, p in ipairs(eligibleParticipants) do
        GlobalEventState.participantsBySource[p.source] = p
        p.joinedTimestamp = GetGameTimer()
        TriggerClientEvent('cidade_tycoon_racing:client:startGlobalEvent', p.source, payload)
    end
end

-- Racing Callbacks
lib.callback.register('cidade_tycoon_racing:server:getLeaderboard', function(source, raceId)
    local query = [[
        SELECT r.*, p.company_name 
        FROM tycoon_race_winners r
        JOIN tycoon_players p ON r.citizenid = p.citizenid
        WHERE r.race_id = ?
        ORDER BY r.time_ms ASC
        LIMIT 10
    ]]
    return MySQL.query.await(query, { raceId or 'global' })
end)

lib.callback.register('cidade_tycoon_racing:server:registerWin', function(source, raceId, vehicleModel, timeMs)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return false end

    -- Base reward calculation
    local reward = 5000 -- Placeholder
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    
    if player then
        player.Functions.AddMoney('bank', reward, 'tycoon-race-win')
        exports.cidade_tycoon_core:LogTransaction(source, reward, 'income', 'race', ('Vitoria na corrida: %s'):format(raceId))
        exports.cidade_tycoon_core:AddExperience(source, 150)
        exports.cidade_tycoon_core:AddReputation(source, 'general', 25) -- Standard Race Win
    end

    MySQL.insert.await([[
        INSERT INTO tycoon_race_winners (race_id, citizenid, vehicle_model, time_ms, reward)
        VALUES (?, ?, ?, ?, ?)
    ]], { raceId, profile.citizenid, vehicleModel, timeMs, reward })

    return true, reward
end)

RegisterNetEvent('cidade_tycoon_racing:server:attemptPriorityDelivery', function(clientEventId)
    local src = source
    if not GlobalEventState.isActive or clientEventId ~= GlobalEventState.eventId or GlobalEventState.winnerSource then return end

    local p = GlobalEventState.participantsBySource[src]
    if not p then return end

    local competitorCount = 0
    for _ in pairs(GlobalEventState.participantsBySource) do competitorCount = competitorCount + 1 end

    local grossReward = EventSystemConfiguration.baseBonusReward + (competitorCount * EventSystemConfiguration.bonusPerCompetitor)
    local skillMult = exports.cidade_tycoon_core:GetTycoonSkillModifier(p.citizenId, 'race_reward_multiplier') or 1.0
    grossReward = math.floor(grossReward * skillMult)

    local taxPercent = math.max(0, EventSystemConfiguration.baseCityTaxPercent - p.efficiencyLevel)
    local netReward = math.floor(grossReward * (1 - (taxPercent / 100)))

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    if player then
        player.Functions.AddMoney('bank', netReward, 'tycoon-priority-win')
        exports.cidade_tycoon_core:AddExperience(src, EventSystemConfiguration.priorityRewardExperience)
        exports.cidade_tycoon_core:AddReputation(src, 'general', 100) -- High Priority Bonus
        exports.cidade_tycoon_core:LogTransaction(src, netReward, 'income', 'race', 'Vitoria Evento Prioridade')
    end

    GlobalEventState.winnerSource = src
    endGlobalPriorityEvent(src, p.displayName, netReward)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    createRacingTables()
    
    CreateThread(function()
        Wait(15000)
        while true do
            Wait(EventSystemConfiguration.triggerIntervalMilliseconds)
            startGlobalPriorityEvent()
        end
    end)
end)

RegisterCommand('tycoon_force_event', function(source)
    if source ~= 0 then return end
    startGlobalPriorityEvent()
end, true)
