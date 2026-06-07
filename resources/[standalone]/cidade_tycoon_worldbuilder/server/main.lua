local config = WorldBuilder.Config
local resourceName = GetCurrentResourceName()
local dataFile = 'data/world.json'
local backupFile = 'data/world.json.bkp'
local activeLocks = {}
local world = { props = {}, removals = {}, externalEntities = {} }

local function notify(source, message, notifyType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'World Builder',
        description = message,
        type = notifyType or 'inform'
    })
end

local function isPlayerAllowed(source)
    if source == 0 or IsPlayerAceAllowed(source, config.permissionAce) then return true end
    if GetResourceState('cidade_tycoon_core') ~= 'started' then return false end

    for _, group in ipairs(config.adminGroups or {}) do
        local ok, allowed = pcall(function()
            return exports.cidade_tycoon_core:HasPermission(source, group)
        end)
        if ok and allowed then return true end
    end
    return false
end

local function validNumber(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return nil end
    return value
end

local function sanitizeVec3(value)
    if type(value) ~= 'table' then return nil end
    local x, y, z = validNumber(value.x), validNumber(value.y), validNumber(value.z)
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

local function sanitizeRotation(value, heading)
    value = type(value) == 'table' and value or {}
    return {
        x = validNumber(value.x) or 0.0,
        y = validNumber(value.y) or 0.0,
        z = validNumber(value.z) or validNumber(heading) or 0.0
    }
end

local function sanitizeProp(payload)
    if type(payload) ~= 'table' then return nil end
    local model = tostring(payload.model or ''):lower():sub(1, 80)
    local coords = sanitizeVec3(payload.coords)
    if model == '' or not coords then return nil end

    local rotation = sanitizeRotation(payload.rotation, payload.heading)
    return {
        id = payload.id,
        label = tostring(payload.label or model):sub(1, 80),
        model = model,
        coords = coords,
        rotation = rotation,
        heading = validNumber(payload.heading) or rotation.z,
        frozen = payload.frozen ~= false,
        collision = payload.collision ~= false,
        target = payload.target ~= false
    }
end

local function sanitizeRemoval(payload)
    if type(payload) ~= 'table' then return nil end
    local model = validNumber(payload.model)
    local coords = sanitizeVec3(payload.coords)
    if not model or not coords then return nil end

    return {
        id = payload.id,
        label = tostring(payload.label or 'Objeto oculto'):sub(1, 80),
        model = model,
        coords = coords,
        radius = math.max(0.5, math.min(validNumber(payload.radius) or config.defaultRadius, 25.0))
    }
end

local function sanitizeExternal(payload)
    if type(payload) ~= 'table' then return nil end
    local entityType = tostring(payload.entityType or payload.type or '')
    local model = validNumber(payload.model)
    local originCoords = sanitizeVec3(payload.originCoords)
    local coords = sanitizeVec3(payload.coords)
    if (entityType ~= 'object' and entityType ~= 'ped' and entityType ~= 'vehicle')
        or not model or not originCoords or not coords then
        return nil
    end

    local rotation = sanitizeRotation(payload.rotation, payload.heading or (payload.coords and payload.coords.w))
    return {
        id = payload.id,
        label = tostring(payload.label or (entityType .. ' ' .. model)):sub(1, 80),
        entityType = entityType,
        model = model,
        originCoords = originCoords,
        coords = coords,
        rotation = rotation,
        heading = validNumber(payload.heading) or validNumber(payload.coords and payload.coords.w) or rotation.z,
        radius = math.max(0.5, math.min(validNumber(payload.radius) or config.defaultExternalRadius, 35.0)),
        frozen = payload.frozen ~= false,
        collision = payload.collision ~= false
    }
end

local function normalizeWorld(decoded)
    if type(decoded) ~= 'table' then return nil end
    return {
        props = type(decoded.props) == 'table' and decoded.props or {},
        removals = type(decoded.removals) == 'table' and decoded.removals or {},
        externalEntities = type(decoded.externalEntities) == 'table' and decoded.externalEntities or {}
    }
end

local function decodeWorld(raw)
    if not raw or raw == '' then return nil end
    local ok, decoded = pcall(json.decode, raw)
    if not ok then return nil end
    return normalizeWorld(decoded)
end

local function loadWorld()
    local primaryRaw = LoadResourceFile(resourceName, dataFile)
    local loaded = decodeWorld(primaryRaw)
    if loaded then
        world = loaded
        return true
    end

    local backupRaw = LoadResourceFile(resourceName, backupFile)
    loaded = decodeWorld(backupRaw)
    if loaded then
        world = loaded
        SaveResourceFile(resourceName, dataFile, backupRaw, -1)
        print('^3[Tycoon:WorldBuilder]^7 world.json restaurado do backup.')
        return true
    end

    world = { props = {}, removals = {}, externalEntities = {} }
    if primaryRaw and primaryRaw ~= '' then
        print('^1[Tycoon:WorldBuilder]^7 world.json e backup invalidos; mundo iniciado vazio.')
    end
    return false
end

local function saveWorld()
    local encoded = json.encode(world)
    if not encoded then return false end

    local currentRaw = LoadResourceFile(resourceName, dataFile)
    if decodeWorld(currentRaw) then
        SaveResourceFile(resourceName, backupFile, currentRaw, -1)
    end

    local saved = SaveResourceFile(resourceName, dataFile, encoded, -1)
    if saved == false then
        print('^1[Tycoon:WorldBuilder]^7 Falha ao salvar world.json.')
        return false
    end
    return true
end

local function findById(collection, id)
    for index, item in ipairs(collection) do
        if item.id == id then return item, index end
    end
end

local function nextId(prefix, collection)
    for _ = 1, 100 do
        local id = ('%s_%d_%04d'):format(prefix, os.time(), math.random(0, 9999))
        if not findById(collection, id) then return id end
    end
    return ('%s_%d_%d'):format(prefix, os.time(), GetGameTimer())
end

local function distanceSquared(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function commit(action, category, data)
    if not saveWorld() then return false end
    TriggerClientEvent('cidade_tycoon_worldbuilder:client:updateObject', -1, action, category, data)
    return true
end

lib.callback.register('cidade_tycoon_worldbuilder:server:getWorld', function(source)
    return world, isPlayerAllowed(source)
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:hasPermission', function(source)
    return isPlayerAllowed(source)
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:requestLock', function(source, objectId)
    if not isPlayerAllowed(source) or type(objectId) ~= 'string' then return false end
    if activeLocks[objectId] and activeLocks[objectId] ~= source then return false end
    activeLocks[objectId] = source
    return true
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:releaseLock', function(source, objectId)
    if activeLocks[objectId] == source then activeLocks[objectId] = nil end
    return true
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:addProp', function(source, payload)
    if not isPlayerAllowed(source) then return { ok = false, message = 'Sem permissao.' } end
    local prop = sanitizeProp(payload)
    if not prop then return { ok = false, message = 'Dados do objeto invalidos.' } end

    prop.id = nextId('prop', world.props)
    prop.createdBy = GetPlayerName(source) or ('source:%s'):format(source)
    prop.createdAt = os.time()
    table.insert(world.props, prop)
    if not commit('add', 'props', prop) then
        table.remove(world.props)
        return { ok = false, message = 'Falha ao salvar o mundo.' }
    end
    return { ok = true, message = 'Objeto adicionado.', id = prop.id }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:updateProp', function(source, id, payload)
    if not isPlayerAllowed(source) then return { ok = false, message = 'Sem permissao.' } end
    local existing, index = findById(world.props, id)
    if not index then return { ok = false, message = 'Objeto nao encontrado.' } end
    if activeLocks[id] and activeLocks[id] ~= source then
        return { ok = false, message = 'Objeto esta sendo editado por outra pessoa.' }
    end

    local prop = sanitizeProp(payload)
    if not prop then return { ok = false, message = 'Dados do objeto invalidos.' } end
    prop.id = existing.id
    prop.createdBy = existing.createdBy
    prop.createdAt = existing.createdAt
    prop.updatedBy = GetPlayerName(source) or ('source:%s'):format(source)
    prop.updatedAt = os.time()
    world.props[index] = prop
    if not commit('update', 'props', prop) then
        world.props[index] = existing
        return { ok = false, message = 'Falha ao salvar o mundo.' }
    end
    return { ok = true, message = 'Objeto atualizado.' }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:deleteProp', function(source, id)
    if not isPlayerAllowed(source) then return { ok = false, message = 'Sem permissao.' } end
    local prop, index = findById(world.props, id)
    if not index then return { ok = false, message = 'Objeto nao encontrado.' } end
    table.remove(world.props, index)
    if not commit('delete', 'props', prop) then
        table.insert(world.props, index, prop)
        return { ok = false, message = 'Falha ao salvar o mundo.' }
    end
    return { ok = true, message = 'Objeto removido.' }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:addRemoval', function(source, payload)
    if not isPlayerAllowed(source) then return { ok = false, message = 'Sem permissao.' } end
    local removal = sanitizeRemoval(payload)
    if not removal then return { ok = false, message = 'Dados da remocao invalidos.' } end

    removal.id = nextId('rem', world.removals)
    removal.createdBy = GetPlayerName(source) or ('source:%s'):format(source)
    removal.createdAt = os.time()
    table.insert(world.removals, removal)
    if not commit('add', 'removals', removal) then
        table.remove(world.removals)
        return { ok = false, message = 'Falha ao salvar o mundo.' }
    end
    return { ok = true, message = 'Remocao registrada.', id = removal.id }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:deleteRemoval', function(source, id)
    if not isPlayerAllowed(source) then return { ok = false, message = 'Sem permissao.' } end
    local removal, index = findById(world.removals, id)
    if not index then return { ok = false, message = 'Remocao nao encontrada.' } end
    table.remove(world.removals, index)
    if not commit('delete', 'removals', removal) then
        table.insert(world.removals, index, removal)
        return { ok = false, message = 'Falha ao salvar o mundo.' }
    end
    return { ok = true, message = 'Remocao desfeita.' }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:addExternalEntity', function(source, payload)
    if not isPlayerAllowed(source) then return { ok = false, message = 'Sem permissao.' } end
    local external = sanitizeExternal(payload)
    if not external then return { ok = false, message = 'Dados da entidade invalidos.' } end

    local existing, index
    if external.id then existing, index = findById(world.externalEntities, external.id) end
    if not index then
        for i, item in ipairs(world.externalEntities) do
            if item.model == external.model and (item.entityType or item.type) == external.entityType
                and item.originCoords and distanceSquared(item.originCoords, external.originCoords) < 1.0 then
                existing, index = item, i
                break
            end
        end
    end

    local action = index and 'update' or 'add'
    if index then
        external.id = existing.id
        external.createdBy = existing.createdBy
        external.createdAt = existing.createdAt
        external.updatedBy = GetPlayerName(source) or ('source:%s'):format(source)
        external.updatedAt = os.time()
        world.externalEntities[index] = external
    else
        external.id = nextId('ext', world.externalEntities)
        external.createdBy = GetPlayerName(source) or ('source:%s'):format(source)
        external.createdAt = os.time()
        table.insert(world.externalEntities, external)
    end

    if not commit(action, 'externalEntities', external) then
        if index then world.externalEntities[index] = existing else table.remove(world.externalEntities) end
        return { ok = false, message = 'Falha ao salvar o mundo.' }
    end
    return { ok = true, message = 'Entidade externa salva.', id = external.id }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:deleteExternalEntity', function(source, id)
    if not isPlayerAllowed(source) then return { ok = false, message = 'Sem permissao.' } end
    local external, index = findById(world.externalEntities, id)
    if not index then return { ok = false, message = 'Entidade nao encontrada.' } end
    table.remove(world.externalEntities, index)
    if not commit('delete', 'externalEntities', external) then
        table.insert(world.externalEntities, index, external)
        return { ok = false, message = 'Falha ao salvar o mundo.' }
    end
    return { ok = true, message = 'Configuracao removida.' }
end)

RegisterCommand('wb_reload', function(source)
    if not isPlayerAllowed(source) then return end
    loadWorld()
    TriggerClientEvent('cidade_tycoon_worldbuilder:client:fullSync', -1, world)
    if source ~= 0 then notify(source, 'Mundo recarregado com sucesso.', 'success') end
end, false)

AddEventHandler('playerDropped', function()
    local source = source
    for id, owner in pairs(activeLocks) do
        if owner == source then activeLocks[id] = nil end
    end
end)

math.randomseed(os.time())
loadWorld()
