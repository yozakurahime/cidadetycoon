local cityConfig = require '@cidade_tycoon_core/shared/city'

local function vectorToTable(vector)
    return {
        x = vector.x + 0.0,
        y = vector.y + 0.0,
        z = vector.z + 0.0,
    }
end

local function normalizeDirection(fromVector, toVector)
    local dx = toVector.x - fromVector.x
    local dy = toVector.y - fromVector.y
    local length = math.sqrt((dx * dx) + (dy * dy))
    if length < 0.001 then return 1.0, 0.0 end
    return dx / length, dy / length
end

local function buildCheckpointSet(route, checkpointWidth)
    local checkpoints = {}
    local distance = 0.0

    for index = 1, #route do
        local current = route[index]
        local nextPoint = route[index + 1] or route[1]
        local dirX, dirY = normalizeDirection(current, nextPoint)
        local lateralX = -dirY * checkpointWidth
        local lateralY = dirX * checkpointWidth

        checkpoints[index] = {
            coords = vectorToTable(current),
            offset = {
                left = { x = current.x + lateralX, y = current.y + lateralY, z = current.z },
                right = { x = current.x - lateralX, y = current.y - lateralY, z = current.z }
            }
        }

        local segmentDx = nextPoint.x - current.x
        local segmentDy = nextPoint.y - current.y
        local segmentDz = nextPoint.z - current.z
        distance = distance + math.sqrt((segmentDx * segmentDx) + (segmentDy * segmentDy) + (segmentDz * segmentDz))
    end

    return checkpoints, math.floor(distance + 0.5)
end

local function seedRace(raceDefinition)
    local existing = MySQL.single.await('SELECT id FROM lapraces WHERE raceid = ? LIMIT 1', { raceDefinition.raceId })
    if existing then return false end

    if not raceDefinition.route or #raceDefinition.route < 2 then return false end

    local checkpoints, totalDistance = buildCheckpointSet(raceDefinition.route, raceDefinition.checkpointWidth or 8.0)

    MySQL.insert.await(
        'INSERT INTO lapraces (name, checkpoints, records, creator, distance, raceid) VALUES (?, ?, ?, ?, ?, ?)',
        {
            raceDefinition.name,
            json.encode(checkpoints),
            json.encode({}),
            cityConfig.raceSeedCreator or 'TycoonAdmin',
            totalDistance,
            raceDefinition.raceId,
        }
    )
    return true
end

CreateThread(function()
    Wait(5000)
    if GetResourceState('qbx_lapraces') ~= 'started' then return end

    local createdCount = 0
    if cityConfig.seedRaces then
        for i = 1, #cityConfig.seedRaces do
            if seedRace(cityConfig.seedRaces[i]) then
                createdCount = createdCount + 1
            end
        end
    end

    if createdCount > 0 then
        print(string.format("^2[Tycoon:Racing]^7 %d corridas oficiais cadastradas.", createdCount))
    end
end)
