local config = WorldBuilder.Config
local world = { props = {}, removals = {}, externalEntities = {} }
local isBuilder = false
local spawned = {}
local worldPoints = {}
local targetNames = {}
local placementActive = false
local placementEntity

local openPropActions
local editProp

local function notify(message, notifyType)
    lib.notify({
        title = 'World Builder',
        description = message,
        type = notifyType or 'inform'
    })
end

local function hasBuilderPermission()
    isBuilder = lib.callback.await('cidade_tycoon_worldbuilder:server:hasPermission', false) == true
    if not isBuilder then notify('Sem permissao para usar o World Builder.', 'error') end
    return isBuilder
end

local function normalizeWorld(data)
    data = type(data) == 'table' and data or {}
    return {
        props = type(data.props) == 'table' and data.props or {},
        removals = type(data.removals) == 'table' and data.removals or {},
        externalEntities = type(data.externalEntities) == 'table' and data.externalEntities or {}
    }
end

local function modelHash(model)
    if type(model) == 'number' then return model end
    if type(model) ~= 'string' or model == '' then return nil end
    return joaat(model)
end

local function requestModel(model)
    local hash = modelHash(model)
    if not hash or not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end

    RequestModel(hash)
    local timeout = GetGameTimer() + 7000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function entityTypeName(entity)
    local entityType = GetEntityType(entity)
    if entityType == 1 then return 'ped' end
    if entityType == 2 then return 'vehicle' end
    if entityType == 3 then return 'object' end
end

local function isEditableEntity(entity)
    if entity == 0 or not DoesEntityExist(entity) or entity == PlayerPedId() then return false end
    if IsEntityAPed(entity) and IsPedAPlayer(entity) then return false end
    if IsEntityAVehicle(entity) then
        local driver = GetPedInVehicleSeat(entity, -1)
        if driver ~= 0 and IsPedAPlayer(driver) then return false end
    end
    return entityTypeName(entity) ~= nil
end

local function ensureEntityControl(entity)
    if not NetworkGetEntityIsNetworked(entity) or NetworkHasControlOfEntity(entity) then return true end
    local timeout = GetGameTimer() + 1000
    repeat
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    until NetworkHasControlOfEntity(entity) or GetGameTimer() >= timeout
    return NetworkHasControlOfEntity(entity)
end

local function getEntityInCrosshair()
    local cameraCoords = GetGameplayCamCoord()
    local cameraRotation = GetGameplayCamRot(2)
    local pitch, yaw = math.rad(cameraRotation.x), math.rad(cameraRotation.z)
    local direction = vec3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
    local destination = cameraCoords + direction * config.maxPlacementDistance
    local ray = StartShapeTestRay(
        cameraCoords.x, cameraCoords.y, cameraCoords.z,
        destination.x, destination.y, destination.z,
        -1, PlayerPedId(), 0
    )

    local state, hit, endCoords, _, entity
    repeat
        state, hit, endCoords, _, entity = GetShapeTestResult(ray)
        if state == 1 then Wait(0) end
    until state ~= 1

    if hit == 1 and entity ~= 0 then return entity, endCoords end
end

local function removeTarget(entity)
    local name = targetNames[entity]
    if name and GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeLocalEntity(entity, name)
    end
    targetNames[entity] = nil
end

local function despawnProp(id)
    local entity = spawned[id]
    if entity and DoesEntityExist(entity) then
        removeTarget(entity)
        DeleteEntity(entity)
    end
    spawned[id] = nil
end

local function spawnProp(prop)
    if not prop.id or not prop.coords then return end
    if spawned[prop.id] and DoesEntityExist(spawned[prop.id]) then return end

    local hash = requestModel(prop.model)
    if not hash then
        print(('[Tycoon:WorldBuilder] Modelo invalido: %s'):format(tostring(prop.model)))
        return
    end

    local entity = CreateObjectNoOffset(hash, prop.coords.x, prop.coords.y, prop.coords.z, false, false, false)
    if entity == 0 then
        SetModelAsNoLongerNeeded(hash)
        return
    end
    placementEntity = entity

    local rotation = type(prop.rotation) == 'table' and prop.rotation or {}
    SetEntityRotation(entity, rotation.x or 0.0, rotation.y or 0.0, rotation.z or prop.heading or 0.0, 2, true)
    FreezeEntityPosition(entity, prop.frozen ~= false)
    SetEntityCollision(entity, prop.collision ~= false, true)
    SetEntityAsMissionEntity(entity, true, true)
    SetModelAsNoLongerNeeded(hash)
    spawned[prop.id] = entity

    if prop.target and GetResourceState('ox_target') == 'started' then
        local name = 'wb_prop_' .. prop.id
        targetNames[entity] = name
        exports.ox_target:addLocalEntity(entity, {
            {
                name = name,
                icon = 'fa-solid fa-cube',
                label = prop.label or tostring(prop.model),
                canInteract = function() return isBuilder end,
                onSelect = function() openPropActions(prop.id) end
            }
        })
    end
end

local function removeWorldPoint(id)
    local point = worldPoints[id]
    if point then point:remove() end
    worldPoints[id] = nil
end

local function registerWorldPoint(prop)
    if not prop.id or not prop.coords then return end
    removeWorldPoint(prop.id)
    local point = lib.points.new({
        coords = vec3(prop.coords.x, prop.coords.y, prop.coords.z),
        distance = config.streamDistance,
        propId = prop.id
    })
    function point:onEnter() spawnProp(prop) end
    function point:onExit() despawnProp(prop.id) end
    worldPoints[prop.id] = point

    if #(GetEntityCoords(PlayerPedId()) - point.coords) <= config.streamDistance then
        spawnProp(prop)
    end
end

local function cleanupWorld()
    for id in pairs(worldPoints) do removeWorldPoint(id) end
    for id in pairs(spawned) do despawnProp(id) end
end

local function setupWorldPoints()
    for _, prop in ipairs(world.props) do registerWorldPoint(prop) end
end

local function findById(collection, id)
    for index, item in ipairs(collection) do
        if item.id == id then return item, index end
    end
end

local function upsert(collection, data)
    local _, index = findById(collection, data.id)
    if index then collection[index] = data else table.insert(collection, data) end
end

local function removeById(collection, id)
    local _, index = findById(collection, id)
    if index then table.remove(collection, index) end
end

local function startPlacement(model, entityType, initial, onSave, onCancel)
    if placementActive then
        notify('Finalize o posicionamento atual primeiro.', 'error')
        return false
    end

    local hash = requestModel(model)
    if not hash then
        notify(('Modelo invalido: %s'):format(tostring(model)), 'error')
        return false
    end

    local ped = PlayerPedId()
    local startCoords = initial and vec3(initial.coords.x, initial.coords.y, initial.coords.z)
        or (GetEntityCoords(ped) + GetEntityForwardVector(ped) * 2.0)
    local entity
    if entityType == 'vehicle' then
        entity = CreateVehicle(hash, startCoords.x, startCoords.y, startCoords.z, 0.0, false, false)
    elseif entityType == 'ped' then
        entity = CreatePed(4, hash, startCoords.x, startCoords.y, startCoords.z, 0.0, false, false)
    else
        entity = CreateObjectNoOffset(hash, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    end
    SetModelAsNoLongerNeeded(hash)
    if entity == 0 then
        notify('Nao foi possivel criar a previa.', 'error')
        return false
    end

    local rotation = initial and initial.rotation or {}
    local heading = initial and (initial.heading or rotation.z) or GetEntityHeading(ped)
    local distance = initial and math.min(#(startCoords - GetEntityCoords(ped)), config.maxPlacementDistance) or 2.0
    local height = 0.0
    local groundSnap = not initial
    placementActive = true

    SetEntityAlpha(entity, 160, false)
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, true)
    SetEntityRotation(entity, rotation.x or 0.0, rotation.y or 0.0, heading or 0.0, 2, true)
    notify('Setas: distancia/rotacao | PageUp/PageDown: altura | G: chao | Enter: salvar | Backspace: cancelar')

    CreateThread(function()
        while placementActive and DoesEntityExist(entity) do
            Wait(0)
            if IsControlPressed(0, 172) then distance = math.min(distance + 0.05, config.maxPlacementDistance) end
            if IsControlPressed(0, 173) then distance = math.max(distance - 0.05, 0.5) end
            if IsControlPressed(0, 174) then heading = heading + 2.0 end
            if IsControlPressed(0, 175) then heading = heading - 2.0 end
            if IsControlPressed(0, 10) then height = height + 0.05 end
            if IsControlPressed(0, 11) then height = height - 0.05 end
            if IsControlJustPressed(0, 47) then groundSnap = not groundSnap end

            local target = GetOffsetFromEntityInWorldCoords(ped, 0.0, distance, height)
            if groundSnap then
                local foundGround, groundZ = GetGroundZFor_3dCoord(target.x, target.y, target.z + 10.0, false)
                if foundGround then target = vec3(target.x, target.y, groundZ) end
            end
            SetEntityCoordsNoOffset(entity, target.x, target.y, target.z, false, false, false)
            SetEntityHeading(entity, heading)

            if IsControlJustPressed(0, 191) then
                local finalCoords = GetEntityCoords(entity)
                local finalHeading = GetEntityHeading(entity)
                DeleteEntity(entity)
                placementEntity = nil
                placementActive = false
                if onSave then onSave(finalCoords, finalHeading) end
                return
            end
            if IsControlJustPressed(0, 177) then
                DeleteEntity(entity)
                placementEntity = nil
                placementActive = false
                if onCancel then onCancel() end
                return
            end
        end
        placementEntity = nil
        placementActive = false
    end)
    return true
end

local function propPayload(prop, coords, heading)
    return {
        label = prop and prop.label or nil,
        model = prop and prop.model or nil,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        rotation = { x = prop and prop.rotation and prop.rotation.x or 0.0, y = prop and prop.rotation and prop.rotation.y or 0.0, z = heading },
        heading = heading,
        frozen = not prop or prop.frozen ~= false,
        collision = not prop or prop.collision ~= false,
        target = not prop or prop.target ~= false
    }
end

local function placeNewProp(model, label)
    startPlacement(model, 'object', nil, function(coords, heading)
        local payload = propPayload({ model = model, label = label or model }, coords, heading)
        local response = lib.callback.await('cidade_tycoon_worldbuilder:server:addProp', false, payload)
        notify(response.message, response.ok and 'success' or 'error')
    end)
end

editProp = function(id)
    local prop = findById(world.props, id)
    if not prop then return notify('Objeto nao encontrado.', 'error') end
    local locked = lib.callback.await('cidade_tycoon_worldbuilder:server:requestLock', false, id)
    if not locked then return notify('Objeto em edicao por outra pessoa.', 'error') end

    local function releaseLock()
        lib.callback.await('cidade_tycoon_worldbuilder:server:releaseLock', false, id)
    end

    local started = startPlacement(prop.model, 'object', prop, function(coords, heading)
        local response = lib.callback.await('cidade_tycoon_worldbuilder:server:updateProp', false, id, propPayload(prop, coords, heading))
        releaseLock()
        notify(response.message, response.ok and 'success' or 'error')
    end, releaseLock)
    if not started then releaseLock() end
end

openPropActions = function(id)
    lib.registerContext({
        id = 'wb_prop_actions',
        title = 'Acoes do objeto',
        options = {
            { title = 'Reposicionar', icon = 'arrows-up-down-left-right', onSelect = function() editProp(id) end },
            {
                title = 'Remover',
                icon = 'trash',
                onSelect = function()
                    local response = lib.callback.await('cidade_tycoon_worldbuilder:server:deleteProp', false, id)
                    notify(response.message, response.ok and 'success' or 'error')
                end
            }
        }
    })
    lib.showContext('wb_prop_actions')
end

local function nearestProp()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearest, nearestDistance
    for _, prop in ipairs(world.props) do
        local distance = #(playerCoords - vec3(prop.coords.x, prop.coords.y, prop.coords.z))
        if distance <= config.editDistance and (not nearestDistance or distance < nearestDistance) then
            nearest, nearestDistance = prop, distance
        end
    end
    return nearest
end

local function poolForType(entityType)
    if entityType == 'ped' then return GetGamePool('CPed') end
    if entityType == 'vehicle' then return GetGamePool('CVehicle') end
    return GetGamePool('CObject')
end

local function findExternalEntity(external)
    local entityType = external.entityType or external.type or 'object'
    local origin = vec3(external.originCoords.x, external.originCoords.y, external.originCoords.z)
    local target = vec3(external.coords.x, external.coords.y, external.coords.z)
    local radius = external.radius or config.defaultExternalRadius
    local closest, closestDistance

    for _, entity in ipairs(poolForType(entityType)) do
        if DoesEntityExist(entity) and GetEntityModel(entity) == external.model and isEditableEntity(entity) then
            local coords = GetEntityCoords(entity)
            local distance = math.min(#(coords - origin), #(coords - target))
            if distance <= radius and (not closestDistance or distance < closestDistance) then
                closest, closestDistance = entity, distance
            end
        end
    end
    return closest
end

local function applyExternal(external)
    if not external.originCoords or not external.coords then return end
    local playerCoords = GetEntityCoords(PlayerPedId())
    local origin = vec3(external.originCoords.x, external.originCoords.y, external.originCoords.z)
    local target = vec3(external.coords.x, external.coords.y, external.coords.z)
    if #(playerCoords - origin) > config.externalScanDistance and #(playerCoords - target) > config.externalScanDistance then return end

    local entity = findExternalEntity(external)
    if not entity or not ensureEntityControl(entity) then return end
    local rotation = type(external.rotation) == 'table' and external.rotation or {}
    local heading = external.heading or external.coords.w or rotation.z or 0.0
    SetEntityCoordsNoOffset(entity, target.x, target.y, target.z, false, false, false)
    SetEntityRotation(entity, rotation.x or 0.0, rotation.y or 0.0, rotation.z or heading, 2, true)
    SetEntityHeading(entity, heading)
    FreezeEntityPosition(entity, external.frozen ~= false)
    SetEntityCollision(entity, external.collision ~= false, true)
end

RegisterNetEvent('cidade_tycoon_worldbuilder:client:fullSync', function(data)
    cleanupWorld()
    world = normalizeWorld(data)
    setupWorldPoints()
    notify('Mundo sincronizado.', 'success')
end)

RegisterNetEvent('cidade_tycoon_worldbuilder:client:updateObject', function(action, category, data)
    local collection = world[category]
    if type(collection) ~= 'table' or type(data) ~= 'table' or not data.id then return end

    if action == 'delete' then removeById(collection, data.id) else upsert(collection, data) end
    if category == 'props' then
        despawnProp(data.id)
        removeWorldPoint(data.id)
        if action ~= 'delete' then registerWorldPoint(data) end
    elseif category == 'externalEntities' and action ~= 'delete' then
        applyExternal(data)
    end
end)

RegisterCommand(config.propCommand, function(_, args)
    if not hasBuilderPermission() then return end
    if not args[1] then return notify(('Uso: /%s [modelo]'):format(config.propCommand), 'error') end
    placeNewProp(args[1], args[1])
end, false)

RegisterCommand('editprop', function()
    if not hasBuilderPermission() then return end
    local prop = nearestProp()
    if not prop then return notify('Nenhum objeto salvo por perto.', 'error') end
    editProp(prop.id)
end, false)

RegisterCommand('hideprop', function()
    if not hasBuilderPermission() then return end
    local entity, hitCoords = getEntityInCrosshair()
    if not entity or GetEntityType(entity) ~= 3 then return notify('Nenhum objeto na mira.', 'error') end
    local coords = GetEntityCoords(entity)
    local response = lib.callback.await('cidade_tycoon_worldbuilder:server:addRemoval', false, {
        model = GetEntityModel(entity),
        coords = { x = coords.x, y = coords.y, z = coords.z },
        radius = config.defaultRadius
    })
    if response.ok and ensureEntityControl(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
    notify(response.message, response.ok and 'success' or 'error')
end, false)

RegisterCommand('moveentity', function()
    if not hasBuilderPermission() then return end
    local entity = getEntityInCrosshair()
    if not entity or not isEditableEntity(entity) then return notify('Entidade invalida ou ocupada.', 'error') end

    local originalCoords = GetEntityCoords(entity)
    local originalRotation = GetEntityRotation(entity, 2)
    local entityType = entityTypeName(entity)
    local model = GetEntityModel(entity)
    startPlacement(model, entityType, {
        coords = { x = originalCoords.x, y = originalCoords.y, z = originalCoords.z },
        rotation = { x = originalRotation.x, y = originalRotation.y, z = originalRotation.z },
        heading = GetEntityHeading(entity)
    }, function(coords, heading)
        local response = lib.callback.await('cidade_tycoon_worldbuilder:server:addExternalEntity', false, {
            model = model,
            entityType = entityType,
            originCoords = { x = originalCoords.x, y = originalCoords.y, z = originalCoords.z },
            coords = { x = coords.x, y = coords.y, z = coords.z },
            rotation = { x = originalRotation.x, y = originalRotation.y, z = heading },
            heading = heading,
            radius = config.defaultExternalRadius,
            frozen = true,
            collision = true
        })
        if response.ok and ensureEntityControl(entity) then
            SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
            SetEntityHeading(entity, heading)
            FreezeEntityPosition(entity, true)
        end
        notify(response.message, response.ok and 'success' or 'error')
    end)
end, false)

RegisterCommand('entitiesmenu', function()
    if not hasBuilderPermission() then return end
    local options = {}
    for _, external in ipairs(world.externalEntities) do
        local item = external
        options[#options + 1] = {
            title = item.label or (tostring(item.entityType or item.type) .. ' ' .. tostring(item.model)),
            description = item.id,
            icon = 'trash',
            onSelect = function()
                local response = lib.callback.await('cidade_tycoon_worldbuilder:server:deleteExternalEntity', false, item.id)
                notify(response.message, response.ok and 'success' or 'error')
            end
        }
    end
    if #options == 0 then options[1] = { title = 'Nenhuma entidade salva', disabled = true } end
    lib.registerContext({ id = 'wb_entities_menu', title = 'Entidades externas', options = options })
    lib.showContext('wb_entities_menu')
end, false)

local function openPresetsMenu()
    local categories = {}
    for categoryIndex, categoryData in ipairs(config.presets or {}) do
        local category = categoryData
        local index = categoryIndex
        categories[#categories + 1] = {
            title = category.label,
            icon = 'boxes-stacked',
            onSelect = function()
                local props = {}
                for _, propData in ipairs(category.props or {}) do
                    local prop = propData
                    props[#props + 1] = {
                        title = prop.label,
                        description = prop.model,
                        icon = 'cube',
                        onSelect = function() placeNewProp(prop.model, prop.label) end
                    }
                end
                local contextId = ('wb_preset_%d'):format(index)
                lib.registerContext({ id = contextId, title = category.label, menu = 'wb_presets', options = props })
                lib.showContext(contextId)
            end
        }
    end
    lib.registerContext({ id = 'wb_presets', title = 'Presets', menu = 'wb_main_menu', options = categories })
    lib.showContext('wb_presets')
end

RegisterCommand(config.command, function()
    if not hasBuilderPermission() then return end
    lib.registerContext({
        id = 'wb_main_menu',
        title = 'WORLD BUILDER',
        options = {
            {
                title = 'Colocar novo prop',
                icon = 'plus',
                onSelect = function()
                    local input = lib.inputDialog('Novo prop', { { type = 'input', label = 'Modelo', required = true } })
                    if input and input[1] then placeNewProp(input[1], input[1]) end
                end
            },
            { title = 'Escolher preset', icon = 'boxes-stacked', onSelect = openPresetsMenu },
            { title = 'Editar prop proximo', icon = 'pen', onSelect = function() ExecuteCommand('editprop') end },
            { title = 'Mover entidade na mira', icon = 'arrows-up-down-left-right', onSelect = function() ExecuteCommand('moveentity') end },
            { title = 'Ocultar objeto na mira', icon = 'eye-slash', onSelect = function() ExecuteCommand('hideprop') end },
            { title = 'Gerenciar entidades externas', icon = 'list', onSelect = function() ExecuteCommand('entitiesmenu') end },
            { title = 'Recarregar mundo', icon = 'rotate', onSelect = function() ExecuteCommand('wb_reload') end }
        }
    })
    lib.showContext('wb_main_menu')
end, false)

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, removal in ipairs(world.removals) do
            if removal.coords and #(playerCoords - vec3(removal.coords.x, removal.coords.y, removal.coords.z)) <= config.removalScanDistance then
                local radius = removal.radius or config.defaultRadius
                local entity = GetClosestObjectOfType(removal.coords.x, removal.coords.y, removal.coords.z, radius, removal.model, false, false, false)
                if entity ~= 0 and ensureEntityControl(entity) then
                    SetEntityAsMissionEntity(entity, true, true)
                    DeleteEntity(entity)
                end
            end
        end
        for _, external in ipairs(world.externalEntities) do applyExternal(external) end
        Wait(config.removalTickMs)
    end
end)

CreateThread(function()
    Wait(1000)
    local data, allowed = lib.callback.await('cidade_tycoon_worldbuilder:server:getWorld', false)
    world = normalizeWorld(data)
    isBuilder = allowed == true
    setupWorldPoints()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if placementEntity and DoesEntityExist(placementEntity) then DeleteEntity(placementEntity) end
    placementEntity = nil
    placementActive = false
    cleanupWorld()
end)
