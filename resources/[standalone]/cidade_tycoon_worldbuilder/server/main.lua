local config = WorldBuilder.Config
local dataFile = 'data/world.json'

local world = {
    props = {},
    removals = {},
    externalEntities = {}
}

local function notify(source, message, notifyType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'World Builder',
        description = message,
        type = notifyType or 'inform'
    })
end

local function hasBuilderPermission(source)
    if source == 0 then return true end
    if IsPlayerAceAllowed(source, config.permissionAce) or IsPlayerAceAllowed(source, 'command') then
        return true
    end

    if GetResourceState('qbx_core') == 'started' then
        for _, group in ipairs(config.adminGroups) do
            if exports.qbx_core:HasPermission(source, group) then
                return true
            end
        end
    end

    return false
end

local function loadWorld()
    local raw = LoadResourceFile(GetCurrentResourceName(), dataFile)
    if not raw or raw == '' then
        world = { props = {}, removals = {}, externalEntities = {} }
        return
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        print(('[%s] Falha ao ler %s, iniciando vazio.'):format(GetCurrentResourceName(), dataFile))
        world = { props = {}, removals = {}, externalEntities = {} }
        return
    end

    world.props = type(decoded.props) == 'table' and decoded.props or {}
    world.removals = type(decoded.removals) == 'table' and decoded.removals or {}
    world.externalEntities = type(decoded.externalEntities) == 'table' and decoded.externalEntities or {}
end

local function saveWorld()
    local encoded = json.encode(world)
    SaveResourceFile(GetCurrentResourceName(), dataFile, encoded, -1)
end

local function nextId(prefix, collection)
    local stamp = os.time()
    local tries = 0

    while tries < 1000 do
        tries = tries + 1
        local id = ('%s_%s_%04d'):format(prefix, stamp, math.random(0, 9999))
        local exists = false
        for _, item in ipairs(collection) do
            if item.id == id then
                exists = true
                break
            end
        end
        if not exists then return id end
    end

    return ('%s_%s_%s'):format(prefix, stamp, tries)
end

local function findById(collection, id)
    for index, item in ipairs(collection) do
        if item.id == id then
            return item, index
        end
    end
end

local function sanitizeVec3(value)
    if type(value) ~= 'table' then return nil end
    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

local function sanitizePlacement(payload)
    if type(payload) ~= 'table' then return nil end
    local model = tostring(payload.model or ''):lower()
    if model == '' or #model > 80 then return nil end

    local coords = sanitizeVec3(payload.coords)
    local rotation = sanitizeVec3(payload.rotation or { x = 0.0, y = 0.0, z = payload.heading or 0.0 })
    if not coords or not rotation then return nil end

    return {
        id = payload.id,
        label = tostring(payload.label or model):sub(1, 80),
        model = model,
        coords = coords,
        rotation = rotation,
        heading = tonumber(payload.heading) or rotation.z or 0.0,
        frozen = payload.frozen ~= false,
        collision = payload.collision ~= false,
        target = payload.target ~= false,
        createdBy = payload.createdBy
    }
end

local function sanitizeExternal(payload)
    if type(payload) ~= 'table' then return nil end

    local entityType = tostring(payload.entityType or '')
    if entityType ~= 'object' and entityType ~= 'ped' and entityType ~= 'vehicle' then return nil end

    local model = tonumber(payload.model)
    local originCoords = sanitizeVec3(payload.originCoords)
    local coords = sanitizeVec3(payload.coords)
    local rotation = sanitizeVec3(payload.rotation or { x = 0.0, y = 0.0, z = payload.heading or 0.0 })
    if not model or not originCoords or not coords or not rotation then return nil end

    return {
        id = payload.id,
        label = tostring(payload.label or 'Entidade externa'):sub(1, 80),
        entityType = entityType,
        model = model,
        originCoords = originCoords,
        coords = coords,
        rotation = rotation,
        heading = tonumber(payload.heading) or rotation.z or 0.0,
        radius = math.max(0.5, math.min(tonumber(payload.radius) or config.defaultExternalRadius, 35.0)),
        frozen = payload.frozen ~= false,
        collision = payload.collision ~= false
    }
end

lib.callback.register('cidade_tycoon_worldbuilder:server:getWorld', function(source)
    return world, hasBuilderPermission(source)
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:hasPermission', function(source)
    return hasBuilderPermission(source)
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:addProp', function(source, payload)
    if not hasBuilderPermission(source) then return { ok = false, message = 'Sem permissao.' } end

    local prop = sanitizePlacement(payload)
    if not prop then return { ok = false, message = 'Dados invalidos.' } end

    prop.id = nextId('prop', world.props)
    prop.createdBy = GetPlayerName(source) or ('source:%s'):format(source)
    prop.createdAt = os.time()

    table.insert(world.props, prop)
    saveWorld()
    TriggerClientEvent('cidade_tycoon_worldbuilder:client:syncWorld', -1, world)

    return { ok = true, message = 'Prop salvo.', id = prop.id }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:updateProp', function(source, id, payload)
    if not hasBuilderPermission(source) then return { ok = false, message = 'Sem permissao.' } end

    local existing = findById(world.props, id)
    if not existing then return { ok = false, message = 'Prop nao encontrado.' } end

    local prop = sanitizePlacement(payload)
    if not prop then return { ok = false, message = 'Dados invalidos.' } end

    existing.label = prop.label
    existing.model = prop.model
    existing.coords = prop.coords
    existing.rotation = prop.rotation
    existing.heading = prop.heading
    existing.frozen = prop.frozen
    existing.collision = prop.collision
    existing.target = prop.target
    existing.updatedBy = GetPlayerName(source) or ('source:%s'):format(source)
    existing.updatedAt = os.time()

    saveWorld()
    TriggerClientEvent('cidade_tycoon_worldbuilder:client:syncWorld', -1, world)

    return { ok = true, message = 'Prop atualizado.' }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:deleteProp', function(source, id)
    if not hasBuilderPermission(source) then return { ok = false, message = 'Sem permissao.' } end

    local _, index = findById(world.props, id)
    if not index then return { ok = false, message = 'Prop nao encontrado.' } end

    table.remove(world.props, index)
    saveWorld()
    TriggerClientEvent('cidade_tycoon_worldbuilder:client:syncWorld', -1, world)

    return { ok = true, message = 'Prop removido.' }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:addRemoval', function(source, payload)
    if not hasBuilderPermission(source) then return { ok = false, message = 'Sem permissao.' } end
    if type(payload) ~= 'table' then return { ok = false, message = 'Dados invalidos.' } end

    local coords = sanitizeVec3(payload.coords)
    local model = tonumber(payload.model)
    if not coords or not model then return { ok = false, message = 'Objeto invalido.' } end

    local removal = {
        id = nextId('hide', world.removals),
        label = tostring(payload.label or 'Mapa oculto'):sub(1, 80),
        model = model,
        coords = coords,
        radius = math.max(0.5, math.min(tonumber(payload.radius) or config.defaultRadius, 25.0)),
        createdBy = GetPlayerName(source) or ('source:%s'):format(source),
        createdAt = os.time()
    }

    table.insert(world.removals, removal)
    saveWorld()
    TriggerClientEvent('cidade_tycoon_worldbuilder:client:syncWorld', -1, world)

    return { ok = true, message = 'Prop do mapa ocultado.', id = removal.id }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:deleteRemoval', function(source, id)
    if not hasBuilderPermission(source) then return { ok = false, message = 'Sem permissao.' } end

    local _, index = findById(world.removals, id)
    if not index then return { ok = false, message = 'Remocao nao encontrada.' } end

    table.remove(world.removals, index)
    saveWorld()
    TriggerClientEvent('cidade_tycoon_worldbuilder:client:syncWorld', -1, world)

    return { ok = true, message = 'Remocao apagada. Reinicie a area para o mapa vanilla voltar.' }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:addExternalEntity', function(source, payload)
    if not hasBuilderPermission(source) then return { ok = false, message = 'Sem permissao.' } end

    local external = sanitizeExternal(payload)
    if not external then return { ok = false, message = 'Dados invalidos.' } end

    external.id = nextId('ext', world.externalEntities)
    external.createdBy = GetPlayerName(source) or ('source:%s'):format(source)
    external.createdAt = os.time()

    table.insert(world.externalEntities, external)
    saveWorld()
    TriggerClientEvent('cidade_tycoon_worldbuilder:client:syncWorld', -1, world)

    return { ok = true, message = 'Posicao externa salva.', id = external.id }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:updateExternalEntity', function(source, id, payload)
    if not hasBuilderPermission(source) then return { ok = false, message = 'Sem permissao.' } end

    local existing = findById(world.externalEntities, id)
    if not existing then return { ok = false, message = 'Entidade externa nao encontrada.' } end

    local external = sanitizeExternal(payload)
    if not external then return { ok = false, message = 'Dados invalidos.' } end

    existing.label = external.label
    existing.entityType = external.entityType
    existing.model = external.model
    existing.originCoords = external.originCoords
    existing.coords = external.coords
    existing.rotation = external.rotation
    existing.heading = external.heading
    existing.radius = external.radius
    existing.frozen = external.frozen
    existing.collision = external.collision
    existing.updatedBy = GetPlayerName(source) or ('source:%s'):format(source)
    existing.updatedAt = os.time()

    saveWorld()
    TriggerClientEvent('cidade_tycoon_worldbuilder:client:syncWorld', -1, world)

    return { ok = true, message = 'Posicao externa atualizada.' }
end)

lib.callback.register('cidade_tycoon_worldbuilder:server:deleteExternalEntity', function(source, id)
    if not hasBuilderPermission(source) then return { ok = false, message = 'Sem permissao.' } end

    local _, index = findById(world.externalEntities, id)
    if not index then return { ok = false, message = 'Entidade externa nao encontrada.' } end

    table.remove(world.externalEntities, index)
    saveWorld()
    TriggerClientEvent('cidade_tycoon_worldbuilder:client:syncWorld', -1, world)

    return { ok = true, message = 'Override externo removido.' }
end)

RegisterCommand('wb_reload', function(source)
    if not hasBuilderPermission(source) then
        notify(source, 'Sem permissao.', 'error')
        return
    end

    loadWorld()
    TriggerClientEvent('cidade_tycoon_worldbuilder:client:syncWorld', -1, world)
    notify(source, 'World Builder recarregado.', 'success')
end, false)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    math.randomseed(os.time())
    loadWorld()
end)

loadWorld()
