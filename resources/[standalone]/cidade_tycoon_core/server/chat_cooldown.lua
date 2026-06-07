local chatCooldowns = {}
local COOLDOWN_TIME = 60 -- segundos

AddEventHandler('chatMessage', function(source, name, message)
    -- Ignorar comandos
    if string.sub(message, 1, 1) == '/' then
        return
    end

    local src = tonumber(source)
    if not src then return end

    -- Obter permissões usando a framework wrapper que já existe em cidade_tycoon_core
    local isStaff = exports.cidade_tycoon_core:HasPermission(src, 'admin')

    if not isStaff then
        local currentTime = os.time()
        
        -- Verifica o Cooldown
        if chatCooldowns[src] and (currentTime - chatCooldowns[src]) < COOLDOWN_TIME then
            local tempoRestante = COOLDOWN_TIME - (currentTime - chatCooldowns[src])
            
            TriggerClientEvent('chat:addMessage', src, {
                template = '<div class="chat-message system"><i class="fas fa-exclamation-circle"></i> <b>AVISO:</b> Aguarde {0}s para enviar outra mensagem. Priorize a comunicação por VOZ!</div>',
                args = { tempoRestante }
            })
            
            -- Cancela o evento original para que o qbx_chat (ou chat base) não envie a mensagem
            CancelEvent()
            return
        end
        
        chatCooldowns[src] = currentTime
        
        -- Envia a mensagem pedagógica para o jogador (sem cancelar a mensagem original)
        TriggerClientEvent('chat:addMessage', src, {
            template = '<div class="chat-message system"><i class="fas fa-info-circle"></i> <b>DICA:</b> Lembre-se: O RP na cidade acontece por VOZ. Evite usar texto.</div>',
            args = {}
        })
    end
end)
