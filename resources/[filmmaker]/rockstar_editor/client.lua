local isRecording = false

local function drawText2D(x, y, text, scale, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

local function chat(message, color)
    TriggerEvent("chat:addMessage", {
        color = color or { 241, 229, 66 },
        multiline = true,
        args = { "[Rockstar Editor]", message }
    })
end

CreateThread(function()
    while true do
        local sleep = 500

        if isRecording then
            sleep = 0
            local alpha = math.floor(128 + 127 * math.sin(GetGameTimer() / 200))
            drawText2D(0.02, 0.02, "REC gravando clipe", 0.45, 220, 20, 20, alpha)
        end

        Wait(sleep)
    end
end)

RegisterCommand("gravar", function()
    if not isRecording then
        StartRecording(1)
        isRecording = true
        chat("Gravacao iniciada. Use /gravar novamente para salvar ou /cancelar para descartar.", { 255, 50, 50 })
    else
        StopRecordingAndSaveClip()
        isRecording = false
        chat("Clipe salvo. Para editar/exportar, saia do servidor e abra o Editor de Replays pela tela inicial do FiveM.", { 50, 255, 120 })
    end
end, false)

RegisterCommand("rec", function()
    ExecuteCommand("gravar")
end, false)

RegisterCommand("cancelar", function()
    if isRecording then
        StopRecordingAndDiscardClip()
        isRecording = false
        chat("Gravacao cancelada e clipe descartado.", { 255, 170, 40 })
    else
        chat("Voce nao esta gravando nenhum clipe agora.", { 255, 80, 80 })
    end
end, false)

RegisterCommand("editor", function()
    chat("Abrindo Rockstar Editor. Se travar, use o fluxo seguro: saia do servidor, abra Editor de Replays na tela inicial, salve o projeto, relogue e exporte.", { 255, 255, 80 })
    Wait(1500)
    ActivateRockstarEditor()
end, false)

RegisterCommand("editorhelp", function()
    chat("/rec ou /gravar: inicia/salva clipe | /cancelar: descarta | /editor: abre Rockstar Editor | EVER: usar somente na maquina de exportacao.", { 241, 229, 66 })
end, false)
