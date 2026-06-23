-- server/main.lua
-- Server-side AFK with configurable kick + admin immunity

local Config = require 'shared.config'
local afkConfig = Config.AFK

local afkSessions = {} -- [source] = { afkSince, warnedKick, vehicleStoppedSince }

-- Check if player has immunity
local function isImmune(source)
    -- Check qbx_afk-style permissions
    local permissions = exports.qbx_core:GetPermission(source)
    for group in pairs(permissions) do
        if afkConfig.ignoreGroups[group] then
            return true
        end
    end

    -- Fallback: ACE check
    if IsPlayerAceAllowed(source, 'admin') or IsPlayerAceAllowed(source, 'mod') then
        return true
    end

    return false
end

-- Register client callback
lib.callback.register('cidade_afk:server:checkAFK', function(source, idleSeconds, inVehicle, vehicleStoppedSeconds)
    if isImmune(source) then
        return { kick = false, ignore = true }
    end

    local session = afkSessions[source]
    if not session then
        afkSessions[source] = { afkSince = 0, warnedKick = false }
        return { kick = false }
    end

    local shouldKick = false
    local kickMessage = nil

    if idleSeconds >= afkConfig.kickTime then
        shouldKick = true
        kickMessage = ('Voce foi desconectado por ficar AFK por mais de %d minutos.'):format(afkConfig.kickTime / 60)
    elseif idleSeconds >= afkConfig.kickTime - afkConfig.kickWarningTime and not session.warnedKick then
        session.warnedKick = true
        return { kick = false, warnKick = true, secondsUntilKick = afkConfig.kickWarningTime }
    end

    if shouldKick then
        DropPlayer(source, kickMessage)
        afkSessions[source] = nil
        return { kick = true }
    end

    return { kick = false }
end)

-- Reset session when player returns from AFK
RegisterNetEvent('cidade_afk:server:resetAFK', function()
    if afkSessions[source] then
        afkSessions[source] = nil
    end
end)

-- Cleanup on disconnect
AddEventHandler('playerDropped', function()
    afkSessions[source] = nil
end)
