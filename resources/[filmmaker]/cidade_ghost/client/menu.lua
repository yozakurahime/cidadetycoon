Menu = {}
Menu.Visible = false
Menu.CurrentMenu = "main"
Menu.SelectedIndex = 1
Menu.Items = {}
Menu.CurrentTrackIndex = nil
Menu.CurrentReplayIndex = nil

-- Register F6 key binding
RegisterCommand('cidade_ghost_menu', function()
    Menu.Visible = not Menu.Visible
    if Menu.Visible then
        Menu.Switch("main")
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    else
        PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    end
end, false)
RegisterKeyMapping('cidade_ghost_menu', 'Menu Cidade Ghost', 'keyboard', 'F7')

---------------------------------------------------
-- Layout constants
---------------------------------------------------
local menuWidth    = 0.26
local menuX        = 0.04
local menuY        = 0.04
local optionHeight = 0.040
local headerHeight = 0.060

---------------------------------------------------
-- Menu definitions
---------------------------------------------------
function Menu.BuildMenus()
    return {
        main = {
            title = "~w~👻 CIDADE GHOST",
            options = {
                { label = "📍 Tracks",               action = function() Menu.Switch("tracks") end },
                { label = "🏁 Criar Nova Track",       action = function() Menu.BeginTrackCreation() end },
                { label = "🎬 Iniciar Gravação",       action = function()
                    Menu.Visible = false
                    TriggerEvent("cidade_ghost:startRecordingFlow")
                end },
                { label = "💾 Parar e Salvar Gravação", action = function()
                    Menu.Visible = false
                    ExecuteCommand("ghost_save")
                end },
                { label = "⚙ Configurações",          action = function() Menu.Switch("settings") end },
                { label = "❌ Fechar Menu",             action = function() Menu.Visible = false end }
            }
        },
        tracks = {
            title = "📍 TRACKS",
            options = {} -- built dynamically
        },
        track_details = {
            title = "TRACK",
            options = {} -- built dynamically
        },
        manage_replays = {
            title = "📁 GRAVAÇÕES",
            options = {} -- built dynamically
        },
        replay_details = {
            title = "🎥 GHOST DETAIL",
            options = {} -- built dynamically
        },
        settings = {
            title = "⚙ CONFIGURAÇÕES",
            options = {
                { label = "Opacidade Ghost", value = Config.Replay.VehicleAlpha, min = 10, max = 255, step = 10, type = "slider", key = "alpha" },
                { label = "Colisão Ghost",   value = Config.Replay.EnableCollision, type = "toggle", key = "collision" },
                { label = "Auto Ghost",      value = Config.Record.AutoGhost, type = "toggle", key = "autoghost" },
                { label = "Mostrar Linhas",  value = Config.General.DrawStartFinish, type = "toggle", key = "drawlines" },
                { label = "Blips do Ghost",  value = Config.General.GhostBlips, type = "toggle", key = "ghostblips" },
                { label = "↩ Voltar",        action = function() Menu.Switch("main") end }
            }
        }
    }
end

local menus = {}

---------------------------------------------------
-- Switching & option population
---------------------------------------------------
function Menu.Switch(menuName, trackIndex)
    menus = Menu.BuildMenus()
    Menu.CurrentMenu = menuName
    Menu.SelectedIndex = 1

    if menuName == "tracks" then
        menus.tracks.options = {}
        for idx, track in ipairs(Storage.Tracks) do
            local replaysCount = Storage.Replays[track.name] and #Storage.Replays[track.name] or 0
            table.insert(menus.tracks.options, {
                label = track.name .. " ~c~(" .. replaysCount .. ")",
                action = function() Menu.ShowTrackDetails(idx) end
            })
        end
        if #Storage.Tracks == 0 then
            table.insert(menus.tracks.options, { label = "~c~Nenhuma track criada", action = function() end })
        end
        table.insert(menus.tracks.options, { label = "↩ Voltar", action = function() Menu.Switch("main") end })

    elseif menuName == "manage_replays" and trackIndex then
        Menu.CurrentTrackIndex = trackIndex
        local track = Storage.Tracks[trackIndex]
        menus.manage_replays.title = "📁 GRAVAÇÕES: " .. track.name
        menus.manage_replays.options = {}
        
        local replays = Storage.Replays[track.name] or {}
        if #replays > 0 then
            table.insert(menus.manage_replays.options, {
                label = "▶ Ativar Todos os Ghosts",
                action = function()
                    Playback.StartAll(track.name)
                    Utils.ShowNotification("~g~Todos os ghosts ativados!")
                    Menu.Switch("manage_replays", trackIndex)
                end
            })
            table.insert(menus.manage_replays.options, {
                label = "⏸ Sincronizar/Resetar Todos",
                action = function()
                    Playback.ResetAllTimes()
                    Utils.ShowNotification("~g~Ghosts sincronizados!")
                    Menu.Switch("manage_replays", trackIndex)
                end
            })
        end

        for idx, r in ipairs(replays) do
            local status = Playback.IsPlaying(r.id) and "~g~[ATIVO]" or "~r~[INATIVO]"
            local pauseStatus = ""
            if Playback.IsPlaying(r.id) then
                local ghost = Playback.ActiveGhosts[r.id]
                if ghost and ghost.paused then
                    pauseStatus = " ~y~(PAUSADO)"
                end
            end
            table.insert(menus.manage_replays.options, {
                label = tostring(idx) .. ". Volta " .. Utils.FormatTime(r.time) .. " " .. status .. pauseStatus,
                action = function() Menu.ShowReplayDetails(trackIndex, idx) end
            })
        end
        
        if #replays == 0 then
            table.insert(menus.manage_replays.options, { label = "~c~Nenhum replay salvo", action = function() end })
        end
        
        table.insert(menus.manage_replays.options, { label = "↩ Voltar", action = function() Menu.ShowTrackDetails(trackIndex) end })
    end

    Menu.Items = menus[Menu.CurrentMenu].options
end

function Menu.ShowTrackDetails(trackIndex)
    menus = Menu.BuildMenus()
    Menu.CurrentMenu = "track_details"
    Menu.SelectedIndex = 1
    Menu.CurrentTrackIndex = trackIndex

    local track = Storage.Tracks[trackIndex]
    local replaysCount = Storage.Replays[track.name] and #Storage.Replays[track.name] or 0
    menus.track_details.title = "🏁 " .. track.name
    menus.track_details.options = {
        { label = "✅ Selecionar como Ativa", action = function()
            TriggerEvent("cidade_ghost:selectTrack", trackIndex)
            Menu.Visible = false
        end },
        { label = "📁 Gerenciar Gravações (" .. replaysCount .. ")", action = function()
            Menu.Switch("manage_replays", trackIndex)
        end },
        { label = "⏹ Parar Todos os Ghosts", action = function()
            Playback.Stop()
            Utils.ShowNotification("~y~Todos os ghosts foram removidos.")
            Menu.ShowTrackDetails(trackIndex)
        end },
        { label = "🗑 Deletar Track", action = function()
            Playback.Stop()
            Storage.DeleteTrack(trackIndex)
            Utils.ShowNotification("~r~Track deletada.")
            TriggerEvent("cidade_ghost:clearTrack")
            Menu.Switch("tracks")
        end },
        { label = "↩ Voltar", action = function() Menu.Switch("tracks") end }
    }
    Menu.Items = menus[Menu.CurrentMenu].options
end

function Menu.ShowReplayDetails(trackIndex, replayIndex, keepIndex)
    local prevIndex = Menu.SelectedIndex
    menus = Menu.BuildMenus()
    Menu.CurrentMenu = "replay_details"
    Menu.CurrentTrackIndex = trackIndex
    Menu.CurrentReplayIndex = replayIndex

    local track = Storage.Tracks[trackIndex]
    local replays = Storage.Replays[track.name]
    local r = replays[replayIndex]

    menus.replay_details.title = "🎥 GHOST #" .. replayIndex
    
    local isPlaying = Playback.IsPlaying(r.id)
    local playLabel = isPlaying and "❌ Desativar Ghost (Remover)" or "▶ Ativar Ghost (Spawn)"
    local ghost = Playback.ActiveGhosts[r.id]
    local pauseLabel = (ghost and ghost.paused) and "▶ Resumir Ghost" or "⏸ Pausar Ghost"
    
    menus.replay_details.options = {
        { label = playLabel, action = function()
            if isPlaying then
                Playback.Stop(r.id)
                Utils.ShowNotification("~r~Ghost desativado.")
            else
                Playback.Start(r)
                Utils.ShowNotification("~g~Ghost ativado!")
            end
            Menu.ShowReplayDetails(trackIndex, replayIndex, true)
        end },
    }

    if isPlaying then
        table.insert(menus.replay_details.options, { label = pauseLabel, action = function()
            local isPaused = Playback.TogglePause(r.id)
            if isPaused ~= nil then
                Utils.ShowNotification(isPaused and "~y~Ghost pausado." or "~g~Ghost resumido.")
            end
            Menu.ShowReplayDetails(trackIndex, replayIndex, true)
        end })

        table.insert(menus.replay_details.options, {
            label = "⚡ Velocidade",
            value = ghost.speed,
            min = 0.1,
            max = 2.0,
            step = 0.1,
            type = "slider",
            key = "replay_speed",
            replayId = r.id
        })

        table.insert(menus.replay_details.options, {
            label = "💥 Colisão",
            value = ghost.collision,
            type = "toggle",
            key = "replay_collision",
            replayId = r.id
        })
    end

    table.insert(menus.replay_details.options, { label = "🗑 Deletar Gravação", action = function()
        Playback.Stop(r.id)
        table.remove(replays, replayIndex)
        local key = "cg_replay_" .. track.name
        SetResourceKvp(key, json.encode(replays))
        Utils.ShowNotification("~r~Gravação deletada.")
        Menu.Switch("manage_replays", trackIndex)
    end })

    table.insert(menus.replay_details.options, { label = "↩ Voltar", action = function() Menu.Switch("manage_replays", trackIndex) end })

    Menu.Items = menus[Menu.CurrentMenu].options
    if keepIndex and prevIndex <= #Menu.Items then
        Menu.SelectedIndex = prevIndex
    else
        Menu.SelectedIndex = 1
    end
end

---------------------------------------------------
-- Drawing
---------------------------------------------------
function Menu.Draw()
    if not Menu.Visible then return end

    local title = menus[Menu.CurrentMenu] and menus[Menu.CurrentMenu].title or "MENU"

    -- Header
    Utils.DrawRect2D(menuX, menuY, menuWidth, headerHeight, 20, 20, 20, 230)
    Utils.DrawRect2D(menuX, menuY + headerHeight - 0.003, menuWidth, 0.003, 100, 200, 255, 255) -- accent line
    Utils.DrawText2D(title, menuX + menuWidth/2, menuY + 0.012, 0.55, 255, 255, 255, 255, 1, 2)

    local currentY = menuY + headerHeight

    for i, item in ipairs(Menu.Items) do
        local isSelected = (i == Menu.SelectedIndex)
        local bgR, bgG, bgB, bgA = 15, 15, 15, 200
        local txtR, txtG, txtB = 200, 200, 200

        if isSelected then
            bgR, bgG, bgB, bgA = 100, 200, 255, 240
            txtR, txtG, txtB = 0, 0, 0
        end

        Utils.DrawRect2D(menuX, currentY, menuWidth, optionHeight, bgR, bgG, bgB, bgA)

        -- Build label text
        local displayText = item.label
        if item.type == "toggle" then
            displayText = displayText .. ": " .. (item.value and "~g~LIGADO" or "~r~DESLIGADO")
        elseif item.type == "slider" then
            displayText = displayText .. ":  < ~b~" .. tostring(item.value) .. "~w~ >"
        end

        Utils.DrawText2D(displayText, menuX + 0.01, currentY + 0.009, 0.34, txtR, txtG, txtB, 255, 0, 0)
        currentY = currentY + optionHeight
    end

    -- Footer bar
    Utils.DrawRect2D(menuX, currentY, menuWidth, 0.025, 20, 20, 20, 200)
    Utils.DrawText2D("F6 Fechar | ↑↓ Navegar | ←→ Ajustar | Enter Selecionar", menuX + menuWidth/2, currentY + 0.004, 0.19, 150, 150, 150, 200, 0, 2)
end

---------------------------------------------------
-- Input handling
---------------------------------------------------
function Menu.HandleInput()
    if not Menu.Visible then return end

    DisableControlAction(0, 1, true)   -- look LR
    DisableControlAction(0, 2, true)   -- look UD
    DisableControlAction(0, 24, true)  -- attack
    DisableControlAction(0, 25, true)  -- aim

    -- Backspace or F6 to close
    if IsControlJustPressed(0, 194) then
        Menu.Visible = false
        PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
        return
    end

    -- Navigation
    if IsControlJustPressed(0, 172) then -- UP
        Menu.SelectedIndex = Menu.SelectedIndex - 1
        if Menu.SelectedIndex < 1 then Menu.SelectedIndex = #Menu.Items end
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)

    elseif IsControlJustPressed(0, 173) then -- DOWN
        Menu.SelectedIndex = Menu.SelectedIndex + 1
        if Menu.SelectedIndex > #Menu.Items then Menu.SelectedIndex = 1 end
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)

    elseif IsControlJustPressed(0, 176) then -- ENTER / SELECT
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
        local item = Menu.Items[Menu.SelectedIndex]
        if item then
            if item.action then
                item.action()
            elseif item.type == "toggle" then
                item.value = not item.value
                Menu.ApplySetting(item.key, item.value, item.replayId)
            elseif item.type == "slider" then
                Menu.PromptSliderValue(item)
            end
        end

    elseif IsControlJustPressed(0, 174) then -- LEFT
        local item = Menu.Items[Menu.SelectedIndex]
        if item and item.type == "slider" then
            item.value = math.max(item.min, item.value - item.step)
            item.value = tonumber(string.format("%.2f", item.value))
            Menu.ApplySetting(item.key, item.value, item.replayId)
            PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
        end

    elseif IsControlJustPressed(0, 175) then -- RIGHT
        local item = Menu.Items[Menu.SelectedIndex]
        if item and item.type == "slider" then
            item.value = math.min(item.max, item.value + item.step)
            item.value = tonumber(string.format("%.2f", item.value))
            Menu.ApplySetting(item.key, item.value, item.replayId)
            PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
        end
    end
end

---------------------------------------------------
-- Prompt Slider Value Manually
---------------------------------------------------
function Menu.PromptSliderValue(item)
    Menu.Visible = false
    CreateThread(function()
        local val = Utils.GetKeyboardInput("Digite o valor (" .. tostring(item.min) .. " - " .. tostring(item.max) .. "):", tostring(item.value), 6)
        if val and tonumber(val) then
            local num = tonumber(val)
            if num < item.min then num = item.min end
            if num > item.max then num = item.max end
            item.value = num
            Menu.ApplySetting(item.key, item.value, item.replayId)
            Utils.ShowNotification("~g~Valor atualizado para: ~w~" .. num)
        else
            Utils.ShowNotification("~r~Valor inválido.")
        end
        Menu.Visible = true
    end)
end

---------------------------------------------------
-- Apply setting changes
---------------------------------------------------
function Menu.ApplySetting(key, value, replayId)
    if key == "alpha" then
        Config.Replay.VehicleAlpha = value
        Storage.SaveConfig()
    elseif key == "collision" then
        Config.Replay.EnableCollision = value
        Storage.SaveConfig()
    elseif key == "autoghost" then
        Config.Record.AutoGhost = value
        Storage.SaveConfig()
    elseif key == "drawlines" then
        Config.General.DrawStartFinish = value
        Storage.SaveConfig()
    elseif key == "ghostblips" then
        Config.General.GhostBlips = value
        Storage.SaveConfig()
    elseif key == "replay_speed" and replayId then
        Playback.SetSpeed(replayId, value)
    elseif key == "replay_collision" and replayId then
        Playback.SetCollision(replayId, value)
    end
end

---------------------------------------------------
-- Track creation trigger
---------------------------------------------------
function Menu.BeginTrackCreation()
    Menu.Visible = false
    TriggerEvent("cidade_ghost:startTrackCreation")
end

