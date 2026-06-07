Config = {}

Config.General = {
    NotifyLaps = true,
    DrawStartFinish = true,
    GhostBlips = true,
    StartStopBlips = true,
    ShowRecordTime = true,
}

Config.Record = {
    AutoGhost = true,
    RecordIntervalMs = 50, -- 20 Hz
    Optional = {
        Lights = true,
        Indicators = true,
        Siren = true
    }
}

Config.Replay = {
    VehicleAlpha = 150,
    ForceLights = 0,
    AutoLoadGhost = true,
    EnableCollision = false,
    DriverModels = {
        "csb_car3guy2",
        "a_m_y_motox_01"
    }
}

Config.Menu = {
    MenuKey = 288, -- F6 in GTA control index (INPUT_REPLAY_START_STOP_RECORDING / F6)
    MenuUp = 172, -- arrow up
    MenuDown = 173, -- arrow down
    MenuLeft = 174, -- arrow left
    MenuRight = 175, -- arrow right
    MenuSelect = 191, -- enter / return
    MenuCancel = 194 -- backspace
}
