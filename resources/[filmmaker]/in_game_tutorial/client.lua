local isOpen = false

-- Função para abrir o painel do tutorial
function OpenTutorial()
    if not isOpen then
        isOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "open"
        })
    end
end

-- Função para fechar o painel do tutorial
function CloseTutorial()
    if isOpen then
        isOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = "close"
        })
    end
end

-- Comando /tutorial para abrir o menu
RegisterCommand('tutorial', function()
    OpenTutorial()
end, false)

-- Atalho /ajuda
RegisterCommand('ajuda', function()
    OpenTutorial()
end, false)

-- Atalho /comandos
RegisterCommand('comandos', function()
    OpenTutorial()
end, false)

-- Callback NUI acionado quando o usuário clica em Fechar ou aperta ESC
RegisterNUICallback('closeTutorial', function(data, cb)
    CloseTutorial()
    cb('ok')
end)

RegisterNUICallback('changeWeather', function(data, cb)
    if data.weather then
        TriggerServerEvent("filmmaker_tools:syncWeather", data.weather)
    end
    cb('ok')
end)

RegisterNUICallback('changeTime', function(data, cb)
    if data.hours ~= nil and data.minutes ~= nil then
        TriggerServerEvent("filmmaker_tools:syncTime", tonumber(data.hours), tonumber(data.minutes), data.freeze == true)
    end
    cb('ok')
end)

-- Notificação no chat ao carregar no servidor
Citizen.CreateThread(function()
    -- Espera 15 segundos após carregar o jogo para mandar a mensagem no chat,
    -- garantindo que o chat já carregou e o jogador consegue ler.
    Citizen.Wait(15000)
    TriggerEvent('chat:addMessage', {
        color = { 0, 191, 255 },
        multiline = true,
        args = {"[Cidade RO]", "Precisa de ajuda com comandos ou fardas? Digite ^2/tutorial^7 no chat!"}
    })
end)
