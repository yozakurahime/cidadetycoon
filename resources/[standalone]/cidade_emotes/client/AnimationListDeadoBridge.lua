local function cloneValue(value)
    if type(value) ~= 'table' then return value end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = cloneValue(child)
    end

    return copy
end

local function addEntry(target, name, data, lowerName)
    if type(target) ~= 'table' or type(data) ~= 'table' then return end
    if data.AdultAnimation and Config.AdultEmotesDisabled then return end

    local key = lowerName and string.lower(name) or name
    if target[key] ~= nil then return end

    target[key] = cloneValue(data)
end

local function addSimpleEntry(target, name, data, valueIndex)
    if type(target) ~= 'table' or type(data) ~= 'table' then return end
    if data.AdultAnimation and Config.AdultEmotesDisabled then return end
    if target[name] ~= nil then return end

    target[name] = { data[valueIndex] or data[1], data[3] }
end

if type(RP) == 'table' and type(DP) == 'table' then
    RP.White4ro = RP.White4ro or {}

    for name, data in pairs(DP.Expressions or {}) do
        addSimpleEntry(RP.Expressions, name, data, 2)
    end

    for name, data in pairs(DP.Walks or {}) do
        addSimpleEntry(RP.Walks, name, data, 1)
    end

    local categoryMap = {
        Shared = RP.Shared,
        Dances = RP.Dances,
        AnimalEmotes = RP.AnimalEmotes,
        Emotes = RP.Emotes,
        PropEmotes = RP.PropEmotes,
        White2do = RP.White2do,
        White3ro = RP.White3ro,
        White4ro = RP.White4ro,
        White5ro = RP.White5to
    }

    for sourceName, target in pairs(categoryMap) do
        for name, data in pairs(DP[sourceName] or {}) do
            addEntry(target, name, data, true)
        end
    end
end
