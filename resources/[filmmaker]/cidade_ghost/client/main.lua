---------------------------------------------------
-- STATE
---------------------------------------------------
local activeTrack       = nil       -- Current selected track
local prevPos           = nil       -- Previous position for line crossing
local isRecordingLap    = false     -- Currently recording a lap?
local lastLapTime       = nil       -- Last completed lap time in ms
local bestLapTime       = nil       -- Best lap time for current track

-- Track creation state
local creatingTrack     = false
local creationStep      = 0         -- 0=nome, 1=startA, 2=startB, 3=finishA, 4=finishB
local tempTrack         = {}
local trackBlips        = {}

---------------------------------------------------
-- INITIALIZATION
---------------------------------------------------
CreateThread(function()
    print("^2[cidade_ghost] Script iniciado! Pressione F7 para abrir o menu.^7")
    Storage.Initialize()
    Menu.Switch("main")
end)

---------------------------------------------------
-- MAIN RENDER & INPUT LOOP
---------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        -- Menu
        Menu.HandleInput()
        Menu.Draw()

        -- Track creation visual feedback
        if creatingTrack then
            DrawTrackCreation(pos)
        end

        -- Active track: draw lines + detect crossings
        if activeTrack and not creatingTrack then
            DrawActiveTrack()
            DetectLineCrossings(pos)
        end

        -- HUD: recording timer
        if isRecordingLap then
            DrawRecordingHUD()
        end

        -- HUD: last lap time flash
        if lastLapTime and not isRecordingLap then
            DrawLapTimeHUD()
        end

        prevPos = pos
    end
end)

---------------------------------------------------
-- TRACK CREATION (Visual step-by-step)
---------------------------------------------------
local creationSteps = {
    [1] = { msg = "Vá até o ~g~PONTO A~w~ da ~g~LINHA DE LARGADA~w~ e pressione ~y~E~w~", color = {0, 255, 0} },
    [2] = { msg = "Vá até o ~g~PONTO B~w~ da ~g~LINHA DE LARGADA~w~ e pressione ~y~E~w~", color = {0, 255, 0} },
    [3] = { msg = "Vá até o ~r~PONTO A~w~ da ~r~LINHA DE CHEGADA~w~ e pressione ~y~E~w~", color = {255, 0, 0} },
    [4] = { msg = "Vá até o ~r~PONTO B~w~ da ~r~LINHA DE CHEGADA~w~ e pressione ~y~E~w~", color = {255, 0, 0} },
}

RegisterNetEvent("cidade_ghost:startTrackCreation", function()
    creatingTrack = true
    creationStep = 0
    tempTrack = {}
    -- Start with name input
    CreateThread(function()
        local name = Utils.GetKeyboardInput("Nome da Track", "Minha Track", 30)
        if not name or name == "" then
            creatingTrack = false
            Utils.ShowNotification("~r~Criação cancelada.")
            return
        end
        tempTrack.name = name
        tempTrack.description = ""
        creationStep = 1
        Utils.ShowNotification("~g~Track: " .. name .. "~w~ | Posicione a linha de largada!")
    end)
end)

function DrawTrackCreation(pos)
    if creationStep < 1 then return end

    local step = creationSteps[creationStep]
    if not step then return end

    -- Help text at top of screen
    Utils.ShowHelpText(step.msg)

    -- Draw preview marker at player feet
    local r, g, b = step.color[1], step.color[2], step.color[3]
    Utils.DrawPlacementPreview(pos, r, g, b, 200)

    -- Draw already-placed points
    if tempTrack.startA then
        Utils.DrawPillar(tempTrack.startA, 0, 255, 0, 200)
    end
    if tempTrack.startB then
        Utils.DrawPillar(tempTrack.startB, 0, 255, 0, 200)
        Utils.DrawLine3D(tempTrack.startA, tempTrack.startB, 0, 255, 0, 200)
    end
    if tempTrack.finishA then
        Utils.DrawPillar(tempTrack.finishA, 255, 0, 0, 200)
    end
    if tempTrack.finishB then
        Utils.DrawPillar(tempTrack.finishB, 255, 0, 0, 200)
        Utils.DrawLine3D(tempTrack.finishA, tempTrack.finishB, 255, 0, 0, 200)
    end

    -- If start line complete, draw it
    if tempTrack.startA and tempTrack.startB and creationStep > 2 then
        Utils.DrawLine3D(tempTrack.startA, tempTrack.startB, 0, 255, 0, 200)
        Utils.DrawPillar(tempTrack.startA, 0, 255, 0, 200)
        Utils.DrawPillar(tempTrack.startB, 0, 255, 0, 200)
    end

    -- E key to confirm point
    if IsControlJustPressed(0, 38) then -- E key
        PlaceTrackPoint(pos)
    end

    -- Backspace to cancel
    if IsControlJustPressed(0, 194) then
        creatingTrack = false
        creationStep = 0
        tempTrack = {}
        Utils.ShowNotification("~r~Criação de track cancelada.")
    end
end

function PlaceTrackPoint(pos)
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)

    if creationStep == 1 then
        tempTrack.startA = pos
        creationStep = 2
        Utils.ShowNotification("~g~Ponto A da LARGADA definido!")

    elseif creationStep == 2 then
        tempTrack.startB = pos
        creationStep = 3
        Utils.ShowNotification("~g~Linha de LARGADA definida! Agora a CHEGADA.")

    elseif creationStep == 3 then
        tempTrack.finishA = pos
        creationStep = 4
        Utils.ShowNotification("~r~Ponto A da CHEGADA definido!")

    elseif creationStep == 4 then
        tempTrack.finishB = pos
        Utils.ShowNotification("~g~Track '" .. tempTrack.name .. "' criada com sucesso!")

        -- Save the track
        local track = {
            name = tempTrack.name,
            description = tempTrack.description or "",
            startLine = {
                a = { x = tempTrack.startA.x, y = tempTrack.startA.y, z = tempTrack.startA.z },
                b = { x = tempTrack.startB.x, y = tempTrack.startB.y, z = tempTrack.startB.z }
            },
            finishLine = {
                a = { x = tempTrack.finishA.x, y = tempTrack.finishA.y, z = tempTrack.finishA.z },
                b = { x = tempTrack.finishB.x, y = tempTrack.finishB.y, z = tempTrack.finishB.z }
            }
        }
        Storage.SaveTrack(track)

        -- Set as active
        activeTrack = track
        UpdateBestTime()
        creatingTrack = false
        creationStep = 0
        tempTrack = {}
    end
end

---------------------------------------------------
-- ACTIVE TRACK: 3D Rendering
---------------------------------------------------
function DrawActiveTrack()
    if not Config.General.DrawStartFinish then return end

    local startA = vector3(activeTrack.startLine.a.x, activeTrack.startLine.a.y, activeTrack.startLine.a.z)
    local startB = vector3(activeTrack.startLine.b.x, activeTrack.startLine.b.y, activeTrack.startLine.b.z)
    local finishA = vector3(activeTrack.finishLine.a.x, activeTrack.finishLine.a.y, activeTrack.finishLine.a.z)
    local finishB = vector3(activeTrack.finishLine.b.x, activeTrack.finishLine.b.y, activeTrack.finishLine.b.z)

    -- Green = Start
    Utils.DrawTrackLine(startA, startB, 0, 255, 0, 200)
    -- Draw ground markers
    local startMid = (startA + startB) / 2.0
    Utils.DrawGroundMarker(startMid, 0, 255, 0, 80, Utils.Distance(startA, startB))

    -- Red = Finish
    Utils.DrawTrackLine(finishA, finishB, 255, 0, 0, 200)
    local finishMid = (finishA + finishB) / 2.0
    Utils.DrawGroundMarker(finishMid, 255, 0, 0, 80, Utils.Distance(finishA, finishB))
end

---------------------------------------------------
-- LINE CROSSING DETECTION
---------------------------------------------------
function DetectLineCrossings(pos)
    if not prevPos then prevPos = pos return end
    if not activeTrack then return end

    local startA = vector3(activeTrack.startLine.a.x, activeTrack.startLine.a.y, activeTrack.startLine.a.z)
    local startB = vector3(activeTrack.startLine.b.x, activeTrack.startLine.b.y, activeTrack.startLine.b.z)
    local finishA = vector3(activeTrack.finishLine.a.x, activeTrack.finishLine.a.y, activeTrack.finishLine.a.z)
    local finishB = vector3(activeTrack.finishLine.b.x, activeTrack.finishLine.b.y, activeTrack.finishLine.b.z)

    -- Must be in a vehicle
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end

    -- CROSSED START LINE
    if Utils.HasCrossedLine(prevPos, pos, startA, startB) then
        if isRecordingLap then
            -- Already recording => this is a new lap (start = finish for circuit tracks)
            -- Only if start line ~= finish line, otherwise wait for finish
            if not AreLinesEqual(activeTrack.startLine, activeTrack.finishLine) then
                -- We crossed start again while recording => ignore or restart
            end
        end
        if not isRecordingLap then
            -- Start recording
            isRecordingLap = Recording.Start()
            if isRecordingLap then
                Utils.ShowNotification("~g~🏁 Gravação iniciada!")
                
                -- Synchronize any manually activated ghosts to the start line
                Playback.ResetAllTimes()
                
                -- If no ghosts are manually running, play the best replay as default
                if not Playback.IsActive() then
                    local best = Storage.GetBestReplay(activeTrack.name)
                    if best then
                        Playback.Start(best)
                    end
                end
            end
        end
    end

    -- CROSSED FINISH LINE
    if isRecordingLap and Utils.HasCrossedLine(prevPos, pos, finishA, finishB) then
        local data, elapsed, model, appearance = Recording.Stop(true)
        isRecordingLap = false

        if data then
            lastLapTime = elapsed
            PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)

            -- Save replay
            Storage.SaveReplay(activeTrack.name, data, model, elapsed, appearance)

            -- Check if new best
            local prevBest = bestLapTime
            UpdateBestTime()

            if not prevBest or elapsed < prevBest then
                Utils.ShowNotification("~p~🏆 NOVO RECORDE! ~w~" .. Utils.FormatTime(elapsed))
            else
                local delta = elapsed - prevBest
                Utils.ShowNotification("~y~Volta: " .. Utils.FormatTime(elapsed) .. " ~w~(+" .. Utils.FormatTime(delta) .. ")")
            end

            -- Stop old ghost and load new best
            Playback.Stop()
        end
    end
end

function AreLinesEqual(l1, l2)
    return l1.a.x == l2.a.x and l1.a.y == l2.a.y and l1.b.x == l2.b.x and l1.b.y == l2.b.y
end

function UpdateBestTime()
    if not activeTrack then bestLapTime = nil return end
    local best = Storage.GetBestReplay(activeTrack.name)
    bestLapTime = best and best.time or nil
end

---------------------------------------------------
-- HUD: Recording Timer
---------------------------------------------------
function DrawRecordingHUD()
    local elapsed = Recording.GetElapsed()

    -- Background bar
    Utils.DrawRect2D(0.40, 0.01, 0.20, 0.055, 0, 0, 0, 180)

    -- "REC" indicator
    Utils.DrawText2D("~r~● REC", 0.415, 0.015, 0.40, 255, 50, 50, 255, 1, 0)

    -- Timer
    Utils.DrawText2D(Utils.FormatTime(elapsed), 0.465, 0.015, 0.50, 255, 255, 255, 255, 1, 0)

    -- Best time comparison
    if bestLapTime then
        Utils.DrawText2D("Best: " .. Utils.FormatTime(bestLapTime), 0.50, 0.045, 0.28, 180, 180, 180, 200, 0, 2)
    end
end

---------------------------------------------------
-- HUD: Last Lap Time (flash for 5 seconds)
---------------------------------------------------
local lastLapShownAt = 0

function DrawLapTimeHUD()
    if not lastLapTime then return end

    if lastLapShownAt == 0 then
        lastLapShownAt = GetGameTimer()
    end

    local timeSince = GetGameTimer() - lastLapShownAt
    if timeSince > 5000 then
        lastLapTime = nil
        lastLapShownAt = 0
        return
    end

    -- Fade out effect
    local alpha = 255
    if timeSince > 3000 then
        alpha = math.floor(255 * (1.0 - (timeSince - 3000) / 2000.0))
    end

    Utils.DrawRect2D(0.35, 0.15, 0.30, 0.07, 0, 0, 0, math.floor(alpha * 0.7))

    local isPB = bestLapTime and lastLapTime <= bestLapTime
    local color = isPB and "~p~" or "~y~"
    local label = isPB and "🏆 RECORDE!" or "✅ Volta Completa"

    Utils.DrawText2D(label, 0.50, 0.155, 0.45, 255, 255, 255, alpha, 1, 2)
    Utils.DrawText2D(color .. Utils.FormatTime(lastLapTime), 0.50, 0.18, 0.60, 255, 255, 255, alpha, 1, 2)
end

---------------------------------------------------
-- EVENT: Select Track
---------------------------------------------------
RegisterNetEvent("cidade_ghost:selectTrack", function(index)
    activeTrack = Storage.Tracks[index]
    if activeTrack then
        UpdateBestTime()
        Utils.ShowNotification("~g~Track ativa: ~y~" .. activeTrack.name)
        if bestLapTime then
            Utils.ShowNotification("~w~Melhor tempo: ~b~" .. Utils.FormatTime(bestLapTime))
        end
        -- Clean previous ghost
        Playback.Stop()
    end
end)

RegisterNetEvent("cidade_ghost:clearTrack", function()
    activeTrack = nil
    bestLapTime = nil
    isRecordingLap = false
    Playback.Stop()
end)

---------------------------------------------------
-- EVENT: Manual Recording Flow (from menu)
---------------------------------------------------
RegisterNetEvent("cidade_ghost:startRecordingFlow", function()
    if isRecordingLap then
        Utils.ShowNotification("~y~Já está gravando! Use /ghost_save para salvar.")
        return
    end
    if not activeTrack then
        Utils.ShowNotification("~r~Selecione uma track primeiro!")
        return
    end
    isRecordingLap = Recording.Start()
    if isRecordingLap then
        Utils.ShowNotification("~g~🎬 Gravação manual iniciada!")
        Utils.ShowNotification("~w~Use ~y~/ghost_save~w~ ou cruze a linha de chegada para salvar.")
    end
end)

---------------------------------------------------
-- MANUAL COMMANDS
---------------------------------------------------

-- Manual stop WITHOUT saving
RegisterCommand("ghost_stop", function()
    if isRecordingLap then
        Recording.Stop(false)
        isRecordingLap = false
        Utils.ShowNotification("~r~Gravação cancelada (não salva).")
    end
    Playback.Stop()
end, false)

-- Manual stop WITH saving
RegisterCommand("ghost_save", function()
    if not isRecordingLap then
        Utils.ShowNotification("~r~Não há gravação em andamento.")
        return
    end
    if not activeTrack then
        Utils.ShowNotification("~r~Nenhuma track selecionada!")
        Recording.Stop(false)
        isRecordingLap = false
        return
    end

    local data, elapsed, model, appearance = Recording.Stop(true)
    isRecordingLap = false

    if data and #data > 0 then
        lastLapTime = elapsed
        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)

        Storage.SaveReplay(activeTrack.name, data, model, elapsed, appearance)

        local prevBest = bestLapTime
        UpdateBestTime()

        Utils.ShowNotification("~g~✅ Replay salvo! Tempo: ~w~" .. Utils.FormatTime(elapsed))
        Utils.ShowNotification("~w~Frames gravados: ~b~" .. #data)

        if not prevBest or elapsed < prevBest then
            Utils.ShowNotification("~p~🏆 NOVO RECORDE!")
        end
    else
        Utils.ShowNotification("~r~Erro: gravação vazia.")
    end
end, false)

-- Info / Debug
RegisterCommand("ghost_info", function()
    if activeTrack then
        Utils.ShowNotification("~b~Track: " .. activeTrack.name)
        if bestLapTime then
            Utils.ShowNotification("~b~Melhor: " .. Utils.FormatTime(bestLapTime))
        end
        local replays = Storage.Replays[activeTrack.name]
        if replays then
            Utils.ShowNotification("~w~Replays salvos: ~b~" .. #replays)
        else
            Utils.ShowNotification("~r~Nenhum replay salvo.")
        end
    else
        Utils.ShowNotification("~r~Nenhuma track selecionada.")
    end
    Utils.ShowNotification("~w~Gravando: " .. (isRecordingLap and "~g~SIM" or "~r~NÃO"))
    Utils.ShowNotification("~w~Ghost ativo: " .. (Playback.IsActive() and "~g~SIM" or "~r~NÃO"))
end, false)

-- Quick record start
RegisterCommand("ghost_rec", function()
    TriggerEvent("cidade_ghost:startRecordingFlow")
end, false)

