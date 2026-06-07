local sharedConfig = require 'config/shared'

local GlobalEventState = {
    isActive = false,
    eventId = 0,
    checkpoint = nil,
    label = '',
    winnersCount = 0,
}

local function DebugLog(text, ...)
    print(string.format("^1[Tycoon:Events]^7 %s", string.format(text, ...)))
end

-- ==========================================
-- DYNAMIC EVENT TRIGGER
-- ==========================================

local function startGlobalPriorityEvent()
    if GlobalEventState.isActive then return end

    local cp = sharedConfig.Events.checkpoints[math.random(#sharedConfig.Events.checkpoints)]
    GlobalEventState.eventId = GlobalEventState.eventId + 1
    GlobalEventState.isActive = true
    GlobalEventState.checkpoint = cp.coords
    GlobalEventState.label = cp.label
    GlobalEventState.winnersCount = 0

    TriggerClientEvent('cidade_tycoon_racing:client:startGlobalEvent', -1, {
        eventId = GlobalEventState.eventId,
        checkpoint = GlobalEventState.checkpoint,
        label = GlobalEventState.label
    })

    DebugLog("Evento #%d iniciado: %s", GlobalEventState.eventId, GlobalEventState.label)
end

-- Timer Loop
CreateThread(function()
    while true do
        local delay = math.random(sharedConfig.Events.minInterval, sharedConfig.Events.maxInterval)
        Wait(delay)
        startGlobalPriorityEvent()
    end
end)

-- ==========================================
-- SERVER VALIDATION (Guardian Rule)
-- ==========================================

RegisterNetEvent('cidade_tycoon_racing:server:attemptPriorityDelivery', function(clientEventId)
    local src = source
    if not GlobalEventState.isActive or clientEventId ~= GlobalEventState.eventId then return end

    -- 1. Class Check (Security)
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        exports.cidade_tycoon_core:NotifyPlayer(src, 'Você precisa estar em um veículo comercial para entregar a carga.', 'error')
        return
    end

    local vClass = GetVehicleClass(vehicle)
    local isAllowed = false
    for _, class in ipairs(sharedConfig.Events.allowedClasses) do
        if vClass == class then isAllowed = true break end
    end

    if not isAllowed then
        exports.cidade_tycoon_core:NotifyPlayer(src, 'Este veículo não possui o porte necessário para esta carga.', 'error')
        return
    end

    -- 2. Position Check
    local pCoords = GetEntityCoords(ped)
    if #(pCoords - GlobalEventState.checkpoint) > 15.0 then
        return -- Too far, possible remote trigger
    end

    -- 3. Tiered Payout (1st, 2nd, 3rd)
    GlobalEventState.winnersCount = GlobalEventState.winnersCount + 1
    local tier = GlobalEventState.winnersCount
    local multiplier = sharedConfig.Events.payoutTiers[tier] or 0

    if multiplier > 0 then
        local baseReward = 45000
        local finalReward = math.floor(baseReward * multiplier)

        exports.cidade_tycoon_core:AddMoney(src, 'bank', finalReward, 'tycoon-priority-delivery')
        exports.cidade_tycoon_core:AddExperience(src, 1000 / tier)
        exports.cidade_tycoon_core:LogTransaction(src, finalReward, 'income', 'event', 'Carga de Prioridade: ' .. GlobalEventState.label)

        TriggerClientEvent('chat:addMessage', -1, {
            template = '<div style="padding: 0.45vw; background: rgba(241, 229, 66, 0.15); border-left: 4px solid #f1e542;"><strong>[LOGÍSTICA]</strong> {0} entregou a carga em {1} lugar e recebeu <strong>${2}</strong>.</div>',
            args = { GetPlayerName(src), tostring(tier), tostring(finalReward) }
        })

        if tier >= 3 then
            GlobalEventState.isActive = false
            TriggerClientEvent('cidade_tycoon_racing:client:stopGlobalEvent', -1, { eventId = GlobalEventState.eventId })
        end
    end
end)

RegisterCommand('tycoon_force_event', function(source)
    if source == 0 then startGlobalPriorityEvent() end
end, true)
