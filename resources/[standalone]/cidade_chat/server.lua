local chatCooldowns = {}
local COOLDOWN_TIME = 60 -- segundos

RegisterNetEvent('cidade_chat:server:sendMessage', function(message)
    local src = source
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    if not player then return end

    local currentTime = os.time()
    if chatCooldowns[src] and (currentTime - chatCooldowns[src]) < COOLDOWN_TIME then
        local tempoRestante = COOLDOWN_TIME - (currentTime - chatCooldowns[src])
        TriggerClientEvent('chat:addMessage', src, {
            author = "SISTEMA",
            message = "Aguarde " .. tempoRestante .. "s para enviar outra mensagem. Priorize a comunicação por VOZ!",
            tag = "AVISO"
        })
        return
    end

    chatCooldowns[src] = currentTime

    local fullName = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
    local tag = "CIDADÃO"

    if exports.cidade_tycoon_core:HasPermission(src, 'admin') then
        tag = "STAFF"
        chatCooldowns[src] = 0 -- Staff não tem cooldown
    end

    TriggerClientEvent('chat:addMessage', -1, {
        author = fullName,
        message = message,
        tag = tag
    })

    -- Aviso pedagógico apenas para quem enviou
    if tag ~= "STAFF" then
        TriggerClientEvent('chat:addMessage', src, {
            author = "DICA",
            message = "Lembre-se: O RP na cidade acontece por VOZ. Evite usar texto.",
            tag = "AVISO"
        })
    end

    -- Log no console do servidor
    print(("^3[CHAT]^7 %s [%d]: %s"):format(fullName, src, message))
end)

-- Substituição de mensagens de sistema padrão (Opcional)
AddEventHandler('chat:addMessage', function(payload)
    -- Se alguém chamar TriggerEvent('chat:addMessage') no servidor
    TriggerClientEvent('chat:addMessage', -1, payload)
end)

-- Exportação para outros recursos enviarem mensagens
exports('addMessage', function(target, payload)
    TriggerClientEvent('chat:addMessage', target, payload)
end)

-- Comando de sistema /clear
RegisterCommand('clear', function(source)
    TriggerClientEvent('chat:clear', source)
end, false)
