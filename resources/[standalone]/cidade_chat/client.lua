local isChatOpen = false
local messageBuffer = {}
local bufferTimeout = 0

local function toggleChat(status)
    isChatOpen = status
    SetNuiFocus(status, status)
    if status then
        SendNUIMessage({ action = 'openChat' })
    else
        SendNUIMessage({ action = 'closeChat' })
    end
end

-- Key Mapping (T ou Y para abrir o chat)
RegisterCommand('openChat', function()
    if not isChatOpen then
        toggleChat(true)
    end
end, false)
RegisterKeyMapping('openChat', 'Abrir Chat', 'keyboard', 'T')

-- EMERGENCY RESCUE COMMAND
RegisterCommand('chat_rescue', function()
    toggleChat(false)
    SetNuiFocus(false, false)
    print("^2[Tycoon:Chat]^7 Foco da NUI resetado via comando de resgate.")
end, false)

-- NUI Callbacks
RegisterNUICallback('chat:focus', function(data, cb)
    if not data.focus then
        SetNuiFocus(false, false)
        isChatOpen = false
    end
    cb('ok')
end)

RegisterNUICallback('chat:submit', function(data, cb)
    if data.message then
        if string.sub(data.message, 1, 1) == "/" then
            ExecuteCommand(string.sub(data.message, 2))
        else
            TriggerServerEvent('cidade_chat:server:sendMessage', data.message)
        end
    end
    cb('ok')
end)

RegisterNetEvent('chat:clear', function()
    SendNUIMessage({ action = 'clear' })
end)

-- Buffered Message Event (Anti-Stutter)
RegisterNetEvent('chat:addMessage', function(payload)
    if type(payload) == 'string' then
        payload = { message = payload, type = 'system' }
    end
    
    table.insert(messageBuffer, payload)

    if bufferTimeout == 0 then
        bufferTimeout = 150 -- 150ms buffer
        SetTimeout(bufferTimeout, function()
            for _, msg in ipairs(messageBuffer) do
                SendNUIMessage({
                    action = 'addMessage',
                    payload = msg
                })
            end
            messageBuffer = {}
            bufferTimeout = 0
        end)
    end
end)

-- Exportação para compatibilidade
exports('addMessage', function(payload)
    TriggerEvent('chat:addMessage', payload)
end)

-- Bloquear controles quando o chat estiver aberto
CreateThread(function()
    while true do
        if isChatOpen then
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 37, true) -- Weapon Wheel
            DisableControlAction(0, 44, true) -- Cover
            DisableControlAction(0, 140, true) -- Light Attack
            DisableControlAction(0, 141, true) -- Heavy Attack
            DisableControlAction(0, 142, true) -- Melee Attack
            DisableControlAction(0, 257, true) -- Melee Attack
            DisableControlAction(0, 263, true) -- Melee Attack
            DisableControlAction(0, 264, true) -- Melee Attack
            Wait(0)
        else
            Wait(500)
        end
    end
end)
