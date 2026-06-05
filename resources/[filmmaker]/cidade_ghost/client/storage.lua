Storage = {}
Storage.Tracks = {}
Storage.Replays = {} -- key = trackName, value = list of replays

---------------------------------------------------
-- Initialization
---------------------------------------------------
function Storage.Initialize()
    -- Load config first
    Storage.LoadConfig()

    -- Load tracks from KVP
    local tracksKvp = GetResourceKvpString("cg_tracks")
    if tracksKvp then
        local ok, data = pcall(json.decode, tracksKvp)
        if ok and data then
            Storage.Tracks = data
            print("[cidade_ghost] Carregadas " .. #Storage.Tracks .. " tracks.")
        end
    end

    -- Load replays for each track
    for _, track in ipairs(Storage.Tracks) do
        local key = "cg_replay_" .. track.name
        local replayKvp = GetResourceKvpString(key)
        if replayKvp then
            local ok, data = pcall(json.decode, replayKvp)
            if ok and data then
                Storage.Replays[track.name] = data
                -- Assign IDs to legacy replays if missing
                for _, r in ipairs(Storage.Replays[track.name]) do
                    if not r.id then
                        r.id = tostring(r.timestamp or GetGameTimer()) .. "_" .. tostring(math.random(1000, 9999))
                    end
                end
            end
        end
    end
end

---------------------------------------------------
-- Track CRUD
---------------------------------------------------
function Storage.SaveTrack(track)
    -- Check if track with same name already exists
    for i, t in ipairs(Storage.Tracks) do
        if t.name == track.name then
            Storage.Tracks[i] = track
            Storage.PersistTracks()
            return
        end
    end
    table.insert(Storage.Tracks, track)
    Storage.PersistTracks()
end

function Storage.DeleteTrack(index)
    local track = Storage.Tracks[index]
    if track then
        -- Also delete associated replays
        local key = "cg_replay_" .. track.name
        DeleteResourceKvp(key)
        Storage.Replays[track.name] = nil
        table.remove(Storage.Tracks, index)
        Storage.PersistTracks()
    end
end

function Storage.PersistTracks()
    SetResourceKvp("cg_tracks", json.encode(Storage.Tracks))
end

---------------------------------------------------
-- Replay CRUD
---------------------------------------------------
function Storage.SaveReplay(trackName, replayData, vehicleModel, lapTimeMs, pedAppearance)
    local entry = {
        id = tostring(GetGameTimer()) .. "_" .. tostring(math.random(1000, 9999)),
        model = vehicleModel,
        time = lapTimeMs,
        timestamp = GetGameTimer(),
        frames = replayData,
        pedAppearance = pedAppearance
    }

    if not Storage.Replays[trackName] then
        Storage.Replays[trackName] = {}
    end

    table.insert(Storage.Replays[trackName], entry)

    -- Sort by time (fastest first)
    table.sort(Storage.Replays[trackName], function(a, b)
        return a.time < b.time
    end)

    -- Keep up to 15 best runs
    if #Storage.Replays[trackName] > 15 then
        table.remove(Storage.Replays[trackName], #Storage.Replays[trackName])
    end

    -- Persist to KVP
    local key = "cg_replay_" .. trackName
    SetResourceKvp(key, json.encode(Storage.Replays[trackName]))
end

function Storage.GetBestReplay(trackName)
    local replays = Storage.Replays[trackName]
    if not replays or #replays == 0 then return nil end
    -- Since they are sorted, index 1 is always the best
    return replays[1]
end

---------------------------------------------------
-- Config Persistence
---------------------------------------------------
function Storage.LoadConfig()
    local configKvp = GetResourceKvpString("cg_config")
    if configKvp then
        local ok, data = pcall(json.decode, configKvp)
        if ok and data then
            if data.alpha ~= nil then Config.Replay.VehicleAlpha = data.alpha end
            if data.collision ~= nil then Config.Replay.EnableCollision = data.collision end
            if data.autoghost ~= nil then Config.Record.AutoGhost = data.autoghost end
            if data.drawlines ~= nil then Config.General.DrawStartFinish = data.drawlines end
            if data.ghostblips ~= nil then Config.General.GhostBlips = data.ghostblips end
            print("[cidade_ghost] Configurações de usuário carregadas.")
        end
    end
end

function Storage.SaveConfig()
    local data = {
        alpha = Config.Replay.VehicleAlpha,
        collision = Config.Replay.EnableCollision,
        autoghost = Config.Record.AutoGhost,
        drawlines = Config.General.DrawStartFinish,
        ghostblips = Config.General.GhostBlips
    }
    SetResourceKvp("cg_config", json.encode(data))
end

