-- ==========================================
-- RATE LIMITER UTILITY
-- ==========================================
-- Prevents callback/event spam from clients
-- Usage: if not exports.cidade_tycoon_core:CheckRateLimit(source, 'action_name', 2000) then return end

local RateLimiter = {}
local callHistory = {}

--- Check if a source is rate-limited for a given action
---@param source number Player server ID
---@param action string Action identifier
---@param cooldownMs number Minimum time between calls in milliseconds
---@return boolean true if allowed, false if rate-limited
function RateLimiter.check(source, action, cooldownMs)
    if not source or source <= 0 then return false end

    local key = tostring(source) .. ':' .. tostring(action)
    local now = GetGameTimer and GetGameTimer() or (os.time() * 1000) -- current time in ms
    local lastCall = callHistory[key] or 0

    if now - lastCall < cooldownMs then
        return false
    end

    callHistory[key] = now
    return true
end

--- Clean up entries for a disconnected player
function RateLimiter.cleanup(source)
    local prefix = tostring(source) .. ':'
    for key in pairs(callHistory) do
        if key:sub(1, #prefix) == prefix then
            callHistory[key] = nil
        end
    end
end

-- Auto-cleanup on player disconnect
AddEventHandler('playerDropped', function(reason)
    RateLimiter.cleanup(source)
end)

-- Export for other resources to use
exports('CheckRateLimit', function(source, action, cooldownMs)
    return RateLimiter.check(source, action, cooldownMs)
end)

return RateLimiter

