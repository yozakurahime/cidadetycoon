local config = WorldBuilder.Config

local world = { props = {}, removals = {}, externalEntities = {} }
local isBuilder = false
local spawned = {}
local targetNames = {}
local placement = nil
local externalApplied = {}
local externalOverridePausedUntil = 0
local externalFallbacks = {}

local function notify(message, notifyType)
    lib.notify({
        title = 'World Builder',
        description = message,
        type = notifyType or 'inform'
    })
end

local function vecToTable(coords)
    return { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 }
end

local function rotationToTable(entity)
    local rot = GetEntityRotation(entity, 2)
    return { x = rot.x + 0.0, y = rot.y + 0.0, z = rot.z + 0.0 }
end

local function entityTypeName(entity)
    if entity == 0 or not DoesEntityExist(entity) then return nil end
    local entityType = GetEntityType(entity)
    if entityType == 1 then return 'ped' end
    if entityType == 2 then return 'vehicle' end
    if entityType == 3 then return 'object' end
    return nil
end

local function poolForType(entityType)
    if entityType == 'ped' then return GetGamePool('CPed') end
    if entityType == 'vehicle' then return GetGamePool('CVehicle') end
    return GetGamePool('CObject')
end

local function isEditableExternalEntity(entity)
    if entity == 0 or not DoesEntityExist(entity) then return false end
    if entity == PlayerPedId() then return false end
    if IsEntityAPed(entity) and IsPedAPlayer(entity) then return false end
    if IsEntityAVehicle(entity) then
        local driver = GetPedInVehicleSeat(entity, -1)
        if driver ~= 0 and IsPedAPlayer(driver) then return false end
    end
    return entityTypeName(entity) ~= nil
end

local function ensureEntityControl(entity)
    if entity == 0 or not DoesEntityExist(entity) then return false end
    if not NetworkGetEntityIsNetworked(entity) then return true end
    if NetworkHasControlOfEntity(entity) then return true end

    NetworkRequestControlOfEntity(entity)
    local timeout = GetGameTimer() + 750
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end

    return NetworkHasControlOfEntity(entity)
end

local function requestModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return nil end

    RequestModel(hash)
    local timeout = GetGameTimer() + 7000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function removeTarget(entity)
    local name = targetNames[entity]
    if name and GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeLocalEntity(entity, name)
    end
    targetNames[entity] = nil
end

local function cleanupSpawned()
    for id, entity in pairs(spawned) do
        if DoesEntityExist(entity) then
            removeTarget(entity)
            DeleteEntity(entity)
        end
        spawned[id] = nil
    end
end

local function cleanupExternalFallback(id)
    local entity = externalFallbacks[id]
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
    externalFallbacks[id] = nil
end

local function cleanupExternalFallbacks()
    for id in pairs(externalFallbacks) do
        cleanupExternalFallback(id)
    end
end

local function addTarget(entity, prop)
    if not prop.target or GetResourceState('ox_target') ~= 'started' then return end

    local name = ('cidade_worldbuilder_%s'):format(prop.id)
    targetNames[entity] = name

    exports.ox_target:addLocalEntity(entity, {
        {
            name = name,
            icon = isBuilder and 'fa-solid fa-pen-to-square' or 'fa-solid fa-circle-info',
            label = isBuilder and ('Editar: ' .. (prop.label or prop.model)) or (prop.label or prop.model),
            distance = 2.5,
            onSelect = function()
                if isBuilder then
                    openPropActions(prop.id)
                else
                    notify(prop.label or prop.model)
                end
            end
        }
    })
end

local function spawnProp(prop)
    if spawned[prop.id] and DoesEntityExist(spawned[prop.id]) then return end

    local hash = requestModel(prop.model)
    if not hash then
        print(('[WorldBuilder] Modelo invalido: %s'):format(tostring(prop.model)))
        return
    end

    local coords = prop.coords
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    local entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityRotation(entity, prop.rotation.x or 0.0, prop.rotation.y or 0.0, prop.rotation.z or prop.heading or 0.0, 2, true)
    SetEntityHeading(entity, prop.heading or prop.rotation.z or 0.0)
    FreezeEntityPosition(entity, prop.frozen ~= false)
    SetEntityCollision(entity, prop.collision ~= false, true)
    SetEntityLoadCollisionFlag(entity, true)
    SetEntityAsMissionEntity(entity, true, true)
    SetModelAsNoLongerNeeded(hash)

    spawned[prop.id] = entity
    addTarget(entity, prop)
end

local function despawnFarProps()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, prop in ipairs(world.props) do
        local dist = #(coords - vec3(prop.coords.x, prop.coords.y, prop.coords.z))
        if dist <= config.streamDistance then
            spawnProp(prop)
        elseif spawned[prop.id] and DoesEntityExist(spawned[prop.id]) then
            removeTarget(spawned[prop.id])
            DeleteEntity(spawned[prop.id])
            spawned[prop.id] = nil
        end
    end
end

local function applyRemovals()
    local playerCoords = GetEntityCoords(PlayerPedId())

    for _, removal in ipairs(world.removals) do
        local center = vec3(removal.coords.x, removal.coords.y, removal.coords.z)
        if #(playerCoords - center) <= config.removalScanDistance then
            local entity = GetClosestObjectOfType(center.x, center.y, center.z, removal.radius or config.defaultRadius, removal.model, false, false, false)
            if entity ~= 0 and DoesEntityExist(entity) then
                SetEntityAsMissionEntity(entity, true, true)
                DeleteEntity(entity)
            end
        end
    end
end

local function findExternal(id)
    for _, external in ipairs(world.externalEntities or {}) do
        if external.id == id then return external end
    end
end

local function findMatchingExternalEntity(external)
    local origin = vec3(external.originCoords.x, external.originCoords.y, external.originCoords.z)
    local target = vec3(external.coords.x, external.coords.y, external.coords.z)
    local radius = math.max(external.radius or config.defaultExternalRadius, 25.0)
    local best, bestDist

    for _, entity in ipairs(poolForType(external.entityType)) do
        if DoesEntityExist(entity) and isEditableExternalEntity(entity) and GetEntityModel(entity) == external.model then
            local coords = GetEntityCoords(entity)
            local distOrigin = #(coords - origin)
            local distTarget = #(coords - target)
            local dist = math.min(distOrigin, distTarget)
            if (distOrigin <= radius or distTarget <= radius) and (not bestDist or dist < bestDist) then
                best = entity
                bestDist = dist
            end
        end
    end

    return best
end

local function findExternalForEntity(entity)
    if not isEditableExternalEntity(entity) then return nil end

    local entityType = entityTypeName(entity)
    local model = GetEntityModel(entity)
    local coords = GetEntityCoords(entity)

    for _, external in ipairs(world.externalEntities or {}) do
        if external.entityType == entityType and external.model == model then
            local origin = vec3(external.originCoords.x, external.originCoords.y, external.originCoords.z)
            local target = vec3(external.coords.x, external.coords.y, external.coords.z)
            local radius = math.max(external.radius or config.defaultExternalRadius, 25.0)

            if #(coords - origin) <= radius or #(coords - target) <= radius then
                return external
            end
        end
    end

    return nil
end

local function resolveExternalPlacement(model, originCoords, entityType)
    local origin = vec3(originCoords.x, originCoords.y, originCoords.z)
    entityType = entityType or 'object'

    for _, external in ipairs(world.externalEntities or {}) do
        if external.entityType == entityType and external.model == model then
            local savedOrigin = vec3(external.originCoords.x, external.originCoords.y, external.originCoords.z)
            local radius = math.max(external.radius or config.defaultExternalRadius, 25.0)

            if #(origin - savedOrigin) <= radius then
                return {
                    id = external.id,
                    coords = external.coords,
                    rotation = external.rotation,
                    heading = external.heading,
                    frozen = external.frozen,
                    collision = external.collision,
                }
            end
        end
    end
end

exports('ResolveExternalPlacement', resolveExternalPlacement)

local function applyExternalOverride(external)
    if placement and placement.mode == 'external' then
        if placement.existingId == external.id then return end
        if placement.entity and DoesEntityExist(placement.entity) then
            local editingExternal = findExternalForEntity(placement.entity)
            if editingExternal and editingExternal.id == external.id then return end
        end
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local origin = vec3(external.originCoords.x, external.originCoords.y, external.originCoords.z)
    local target = vec3(external.coords.x, external.coords.y, external.coords.z)

    if #(playerCoords - origin) > config.externalScanDistance and #(playerCoords - target) > config.externalScanDistance then
        cleanupExternalFallback(external.id)
        return
    end

    local entity = findMatchingExternalEntity(external)
    if not entity then
        if external.entityType == 'object' then
            local fallback = externalFallbacks[external.id]
            if fallback and DoesEntityExist(fallback) then return end

            local hash = requestModel(external.model)
            if not hash then return end

            RequestCollisionAtCoord(target.x, target.y, target.z)
            fallback = CreateObjectNoOffset(hash, target.x, target.y, target.z, false, false, false)
            SetEntityRotation(fallback, external.rotation.x or 0.0, external.rotation.y or 0.0, external.rotation.z or external.heading or 0.0, 2, true)
            SetEntityHeading(fallback, external.heading or external.rotation.z or 0.0)
            FreezeEntityPosition(fallback, external.frozen ~= false)
            SetEntityCollision(fallback, external.collision ~= false, true)
            SetEntityLoadCollisionFlag(fallback, true)
            SetEntityAsMissionEntity(fallback, true, true)
            SetEntityAlpha(fallback, 235, false)
            SetModelAsNoLongerNeeded(hash)
            externalFallbacks[external.id] = fallback
        end
        return
    end

    cleanupExternalFallback(external.id)
    if not ensureEntityControl(entity) then return end

    SetEntityCoordsNoOffset(entity, target.x, target.y, target.z, false, false, false)
    SetEntityRotation(entity, external.rotation.x or 0.0, external.rotation.y or 0.0, external.rotation.z or external.heading or 0.0, 2, true)
    SetEntityHeading(entity, external.heading or external.rotation.z or 0.0)
    FreezeEntityPosition(entity, external.frozen ~= false)
    SetEntityCollision(entity, external.collision ~= false, true)
    SetEntityAsMissionEntity(entity, true, true)

    if external.entityType == 'ped' then
        SetBlockingOfNonTemporaryEvents(entity, true)
        SetPedCanRagdoll(entity, false)
    end

    externalApplied[external.id] = entity
end

local function applyExternalOverrides()
    if placement and placement.mode == 'external' then return end
    if GetGameTimer() < externalOverridePausedUntil then return end

    for _, external in ipairs(world.externalEntities or {}) do
        applyExternalOverride(external)
    end
end

local function findProp(id)
    for _, prop in ipairs(world.props) do
        if prop.id == id then return prop end
    end
end

local function nearestPlacedProp()
    local coords = GetEntityCoords(PlayerPedId())
    local best, bestDist

    for _, prop in ipairs(world.props) do
        local dist = #(coords - vec3(prop.coords.x, prop.coords.y, prop.coords.z))
        if dist <= config.editDistance and (not bestDist or dist < bestDist) then
            best, bestDist = prop, dist
        end
    end

    return best, bestDist
end

local function cameraRay(distance, ignoredEntity)
    local camRot = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local pitch = math.rad(camRot.x)
    local yaw = math.rad(camRot.z)
    local direction = vec3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
    local destination = camCoord + direction * distance
    local ignore = ignoredEntity or PlayerPedId()
    local ray = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, destination.x, destination.y, destination.z, -1, ignore, 0)
    local _, hit, endCoords, _, entity = GetShapeTestResult(ray)
    if entity == PlayerPedId() or entity == ignoredEntity then
        return false, destination, entity
    end
    return hit == 1, endCoords, entity
end

local function placementPayload(entity, model, label, id)
    local coords = GetEntityCoords(entity)
    return {
        id = id,
        label = label or model,
        model = model,
        coords = vecToTable(coords),
        rotation = rotationToTable(entity),
        heading = GetEntityHeading(entity),
        frozen = true,
        collision = true,
        target = true
    }
end

local function externalPayload()
    local entity = placement and placement.entity
    if not entity or not DoesEntityExist(entity) then return nil end

    return {
        id = placement.existingId,
        label = placement.label,
        entityType = placement.entityType,
        model = placement.modelHash,
        originCoords = placement.originCoords,
        coords = vecToTable(GetEntityCoords(entity)),
        rotation = rotationToTable(entity),
        heading = GetEntityHeading(entity),
        radius = placement.radius or config.defaultExternalRadius,
        frozen = true,
        collision = true
    }
end

local function drawHelpText(lines)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(table.concat(lines, '~n~'))
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function stopPlacement(deletePreview)
    if placement and placement.entity and DoesEntityExist(placement.entity) then
        if placement.mode == 'external' and deletePreview and placement.restore then
            local restore = placement.restore
            SetEntityCoordsNoOffset(placement.entity, restore.coords.x, restore.coords.y, restore.coords.z, false, false, false)
            SetEntityRotation(placement.entity, restore.rotation.x, restore.rotation.y, restore.rotation.z, 2, true)
            SetEntityHeading(placement.entity, restore.heading)
            FreezeEntityPosition(placement.entity, restore.frozen)
            SetEntityCollision(placement.entity, restore.collision, true)
            ResetEntityAlpha(placement.entity)
        elseif deletePreview then
            DeleteEntity(placement.entity)
        else
            ResetEntityAlpha(placement.entity)
            SetEntityCollision(placement.entity, true, true)
        end
    end
    placement = nil
end

local function startPlacement(model, label, existing)
    if placement then stopPlacement(true) end

    local hash = requestModel(model)
    if not hash then
        notify(('Modelo invalido: %s'):format(model), 'error')
        return
    end

    local coords
    local heading = GetEntityHeading(PlayerPedId())
    if existing then
        coords = vec3(existing.coords.x, existing.coords.y, existing.coords.z)
        heading = existing.heading or existing.rotation.z or heading
    else
        coords = GetEntityCoords(PlayerPedId()) + GetEntityForwardVector(PlayerPedId()) * 2.0
    end

    local entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityAlpha(entity, 185, false)
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, true)
    SetEntityHeading(entity, heading)
    SetEntityAsMissionEntity(entity, true, true)
    SetModelAsNoLongerNeeded(hash)

    placement = {
        mode = 'prop',
        entity = entity,
        model = model,
        label = label or model,
        existingId = existing and existing.id or nil,
        distance = 3.0,
        zOffset = 0.0,
        heading = heading,
        pitch = existing and (existing.rotation.x or 0.0) or 0.0,
        roll = existing and (existing.rotation.y or 0.0) or 0.0,
        snapToGround = true
    }

    notify('Modo de construcao ativo. Use ENTER para salvar.', 'inform')
end

local function startExternalPlacement(entity, existing)
    if placement then stopPlacement(true) end
    if not isEditableExternalEntity(entity) then
        notify('Essa entidade nao pode ser editada.', 'error')
        return
    end
    if not ensureEntityControl(entity) then
        notify('Nao consegui controle dessa entidade. Tente chegar mais perto ou reiniciar o resource que criou ela.', 'error')
        return
    end

    local coords = GetEntityCoords(entity)
    local rotation = rotationToTable(entity)
    local heading = GetEntityHeading(entity)
    local entityType = entityTypeName(entity)
    local model = GetEntityModel(entity)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local startDistance = math.max(0.6, math.min(config.maxPlacementDistance, #(coords - playerCoords)))
    externalOverridePausedUntil = GetGameTimer() + 15000

    placement = {
        mode = 'external',
        entity = entity,
        entityType = entityType,
        modelHash = model,
        label = existing and existing.label or ('%s %s'):format(entityType, model),
        existingId = existing and existing.id or nil,
        originCoords = existing and existing.originCoords or vecToTable(coords),
        radius = existing and existing.radius or config.defaultExternalRadius,
        distance = startDistance,
        zOffset = 0.0,
        heading = existing and (existing.heading or existing.rotation.z) or heading,
        pitch = existing and (existing.rotation.x or 0.0) or rotation.x,
        roll = existing and (existing.rotation.y or 0.0) or rotation.y,
        snapToGround = false,
        restore = {
            coords = vecToTable(coords),
            rotation = rotation,
            heading = heading,
            frozen = IsEntityPositionFrozen(entity),
            collision = true
        }
    }

    SetEntityAlpha(entity, 190, false)
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, true)
    notify(existing and 'Editando posicao salva. ENTER atualiza.' or 'Movendo entidade existente. ENTER salva e persiste.', 'inform')
end

local function savePlacement()
    if not placement or not DoesEntityExist(placement.entity) then return end

    local payload
    local result

    if placement.mode == 'external' then
        payload = externalPayload()
        if placement.existingId then
            result = lib.callback.await('cidade_tycoon_worldbuilder:server:updateExternalEntity', false, placement.existingId, payload)
        else
            result = lib.callback.await('cidade_tycoon_worldbuilder:server:addExternalEntity', false, payload)
        end
    else
        payload = placementPayload(placement.entity, placement.model, placement.label, placement.existingId)
        if placement.existingId then
            result = lib.callback.await('cidade_tycoon_worldbuilder:server:updateProp', false, placement.existingId, payload)
        else
            result = lib.callback.await('cidade_tycoon_worldbuilder:server:addProp', false, payload)
        end
    end

    local mode = placement.mode
    notify(result.message or 'Salvo.', result.ok and 'success' or 'error')
    if mode == 'external' then
        externalOverridePausedUntil = GetGameTimer() + 4000
    end
    stopPlacement(mode ~= 'external')
end

CreateThread(function()
    while true do
        if not placement or not DoesEntityExist(placement.entity) then
            Wait(250)
        else
            Wait(0)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            if placement.mode == 'external' then
                DisableControlAction(0, 32, true)
                DisableControlAction(0, 33, true)
                DisableControlAction(0, 34, true)
                DisableControlAction(0, 35, true)
                DisableControlAction(0, 38, true)
                DisableControlAction(0, 44, true)
            end

            if IsControlPressed(0, 172) then placement.distance = math.min(config.maxPlacementDistance, placement.distance + 0.05) end
            if IsControlPressed(0, 173) then placement.distance = math.max(0.6, placement.distance - 0.05) end
            if IsControlPressed(0, 174) then placement.heading = placement.heading + 1.0 end
            if IsControlPressed(0, 175) then placement.heading = placement.heading - 1.0 end
            if IsControlPressed(0, 10) then placement.zOffset = placement.zOffset + 0.015 end
            if IsControlPressed(0, 11) then placement.zOffset = placement.zOffset - 0.015 end

            if IsControlJustPressed(0, 47) then
                placement.snapToGround = not placement.snapToGround
                notify(placement.snapToGround and 'Snap no chao ligado.' or 'Snap no chao desligado.')
            end

            if IsControlJustPressed(0, 191) then
                savePlacement()
            elseif IsControlJustPressed(0, 177) then
                notify('Colocacao cancelada.', 'error')
                if placement.mode == 'external' then
                    externalOverridePausedUntil = GetGameTimer() + 2500
                end
                stopPlacement(true)
            end

            if placement.mode == 'external' and not ensureEntityControl(placement.entity) then
                drawHelpText({ 'World Builder', 'Tentando pegar controle da entidade...' })
                goto continuePlacement
            end

            local hit, endCoords = cameraRay(placement.distance, placement.entity)
            local coords = hit and endCoords or (GetEntityCoords(PlayerPedId()) + GetEntityForwardVector(PlayerPedId()) * placement.distance)
            coords = vec3(coords.x, coords.y, coords.z + placement.zOffset)

            if placement.mode == 'external' then
                local current = GetEntityCoords(placement.entity)
                local camRot = GetGameplayCamRot(2)
                local yaw = math.rad(camRot.z)
                local forward = vec3(-math.sin(yaw), math.cos(yaw), 0.0)
                local right = vec3(forward.y, -forward.x, 0.0)
                local nudge = vec3(0.0, 0.0, 0.0)
                local step = IsControlPressed(0, 21) and 0.08 or 0.025

                if IsDisabledControlPressed(0, 32) then nudge = nudge + forward * step end
                if IsDisabledControlPressed(0, 33) then nudge = nudge - forward * step end
                if IsDisabledControlPressed(0, 34) then nudge = nudge - right * step end
                if IsDisabledControlPressed(0, 35) then nudge = nudge + right * step end
                if IsDisabledControlPressed(0, 44) then nudge = nudge + vec3(0.0, 0.0, step) end
                if IsDisabledControlPressed(0, 38) then nudge = nudge - vec3(0.0, 0.0, step) end

                if #(nudge) > 0.0 then
                    coords = current + nudge
                    placement.zOffset = 0.0
                end
            end

            SetEntityCoordsNoOffset(placement.entity, coords.x, coords.y, coords.z, false, false, false)
            if placement.snapToGround then
                PlaceObjectOnGroundProperly(placement.entity)
                local grounded = GetEntityCoords(placement.entity)
                SetEntityCoordsNoOffset(placement.entity, grounded.x, grounded.y, grounded.z + placement.zOffset, false, false, false)
            end
            SetEntityRotation(placement.entity, placement.pitch, placement.roll, placement.heading, 2, true)

            drawHelpText({
                'World Builder',
                'Setas cima/baixo: distancia',
                'Setas esquerda/direita: girar',
                'PageUp/PageDown: altura',
                'WASD/Q/E: ajuste fino',
                'G: grudar no chao',
                'ENTER: salvar | BACKSPACE: cancelar'
            })

            ::continuePlacement::
        end
    end
end)

local function openPresetCategory(category)
    local options = {}
    for _, prop in ipairs(category.props) do
        options[#options + 1] = {
            title = prop.label,
            description = prop.model,
            icon = 'cube',
            onSelect = function()
                startPlacement(prop.model, prop.label)
            end
        }
    end

    lib.registerContext({
        id = 'cidade_worldbuilder_category_' .. category.label:gsub('%W+', '_'),
        title = category.label,
        menu = 'cidade_worldbuilder_main',
        options = options
    })
    lib.showContext('cidade_worldbuilder_category_' .. category.label:gsub('%W+', '_'))
end

local function promptCustomProp()
    local input = lib.inputDialog('Colocar Prop', {
        { type = 'input', label = 'Modelo GTA', placeholder = 'prop_toolchest_01', required = true },
        { type = 'input', label = 'Nome no editor', placeholder = 'Bancada de pecas' }
    })

    if not input then return end
    startPlacement(input[1], input[2] ~= '' and input[2] or input[1])
end

function openPropActions(propId)
    local prop = findProp(propId)
    if not prop then return end

    lib.registerContext({
        id = 'cidade_worldbuilder_prop_actions',
        title = prop.label or prop.model,
        options = {
            {
                title = 'Mover / Girar',
                icon = 'arrows-up-down-left-right',
                onSelect = function()
                    if spawned[prop.id] and DoesEntityExist(spawned[prop.id]) then
                        DeleteEntity(spawned[prop.id])
                        spawned[prop.id] = nil
                    end
                    startPlacement(prop.model, prop.label, prop)
                end
            },
            {
                title = 'Renomear',
                icon = 'tag',
                onSelect = function()
                    local input = lib.inputDialog('Renomear Prop', {
                        { type = 'input', label = 'Nome', default = prop.label or prop.model, required = true }
                    })
                    if not input then return end
                    prop.label = input[1]
                    local result = lib.callback.await('cidade_tycoon_worldbuilder:server:updateProp', false, prop.id, prop)
                    notify(result.message, result.ok and 'success' or 'error')
                end
            },
            {
                title = 'Remover prop salvo',
                icon = 'trash',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Remover prop?',
                        content = prop.label or prop.model,
                        centered = true,
                        cancel = true
                    })
                    if confirm ~= 'confirm' then return end
                    local result = lib.callback.await('cidade_tycoon_worldbuilder:server:deleteProp', false, prop.id)
                    notify(result.message, result.ok and 'success' or 'error')
                end
            }
        }
    })

    lib.showContext('cidade_worldbuilder_prop_actions')
end

local function editNearest()
    local prop = nearestPlacedProp()
    if not prop then
        notify(('Nenhum prop salvo em %.1fm.'):format(config.editDistance), 'error')
        return
    end
    openPropActions(prop.id)
end

local function moveAimedExternal()
    local hit, _, entity = cameraRay(35.0)
    if not hit or not isEditableExternalEntity(entity) then
        notify('Mire em uma prop, NPC ou veiculo vazio de outro script.', 'error')
        return
    end

    local entityType = entityTypeName(entity)
    local existing = findExternalForEntity(entity)
    local input = lib.inputDialog('Mover entidade existente', {
        { type = 'input', label = 'Nome no editor', default = existing and existing.label or ('%s %s'):format(entityType, GetEntityModel(entity)), required = true },
        { type = 'number', label = 'Raio para encontrar ao reiniciar', default = existing and existing.radius or config.defaultExternalRadius, min = 0.5, max = 35.0 }
    })
    if not input then return end

    startExternalPlacement(entity, existing)
    if placement then
        placement.label = input[1]
        placement.radius = tonumber(input[2]) or config.defaultExternalRadius
    end
end

local function openExternalActions(externalId)
    local external = findExternal(externalId)
    if not external then return end

    lib.registerContext({
        id = 'cidade_worldbuilder_external_actions',
        title = external.label or tostring(external.model),
        options = {
            {
                title = 'Mover / Girar entidade',
                description = 'Precisa estar perto da entidade original ou da posicao salva.',
                icon = 'arrows-up-down-left-right',
                onSelect = function()
                    local entity = findMatchingExternalEntity(external)
                    if not entity then
                        notify('Nao encontrei essa entidade por perto agora.', 'error')
                        return
                    end
                    startExternalPlacement(entity, external)
                end
            },
            {
                title = 'Renomear / ajustar raio',
                icon = 'tag',
                onSelect = function()
                    local input = lib.inputDialog('Editar override', {
                        { type = 'input', label = 'Nome', default = external.label or tostring(external.model), required = true },
                        { type = 'number', label = 'Raio', default = external.radius or config.defaultExternalRadius, min = 0.5, max = 35.0 }
                    })
                    if not input then return end
                    external.label = input[1]
                    external.radius = tonumber(input[2]) or config.defaultExternalRadius
                    local result = lib.callback.await('cidade_tycoon_worldbuilder:server:updateExternalEntity', false, external.id, external)
                    notify(result.message, result.ok and 'success' or 'error')
                end
            },
            {
                title = 'Remover override',
                description = 'O script original volta a posicionar a entidade normalmente.',
                icon = 'trash',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Remover override?',
                        content = external.label or tostring(external.model),
                        centered = true,
                        cancel = true
                    })
                    if confirm ~= 'confirm' then return end
                    local result = lib.callback.await('cidade_tycoon_worldbuilder:server:deleteExternalEntity', false, external.id)
                    notify(result.message, result.ok and 'success' or 'error')
                end
            }
        }
    })

    lib.showContext('cidade_worldbuilder_external_actions')
end

local function openExternalMenu()
    local options = {}

    for _, external in ipairs(world.externalEntities or {}) do
        options[#options + 1] = {
            title = external.label or tostring(external.model),
            description = ('%s | raio %.1fm'):format(external.entityType or 'entity', external.radius or 0.0),
            icon = external.entityType == 'ped' and 'user' or 'cube',
            onSelect = function()
                openExternalActions(external.id)
            end
        }
    end

    if #options == 0 then
        options[1] = { title = 'Nenhuma entidade externa salva', disabled = true }
    end

    lib.registerContext({
        id = 'cidade_worldbuilder_external',
        title = 'Entidades de outros scripts',
        menu = 'cidade_worldbuilder_main',
        options = options
    })
    lib.showContext('cidade_worldbuilder_external')
end

local function hideMapObject()
    local hit, endCoords, entity = cameraRay(30.0)
    if not hit or entity == 0 or not DoesEntityExist(entity) then
        notify('Mire em um objeto do mapa primeiro.', 'error')
        return
    end

    local model = GetEntityModel(entity)
    local coords = GetEntityCoords(entity)
    local input = lib.inputDialog('Ocultar prop do mapa', {
        { type = 'input', label = 'Nome', default = ('Modelo %s'):format(model) },
        { type = 'number', label = 'Raio', default = config.defaultRadius, min = 0.5, max = 25.0 }
    })
    if not input then return end

    local result = lib.callback.await('cidade_tycoon_worldbuilder:server:addRemoval', false, {
        label = input[1],
        model = model,
        coords = vecToTable(coords),
        radius = tonumber(input[2]) or config.defaultRadius
    })

    if result.ok then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
    notify(result.message, result.ok and 'success' or 'error')
end

local function openRemovalsMenu()
    local options = {}

    for _, removal in ipairs(world.removals) do
        options[#options + 1] = {
            title = removal.label or tostring(removal.model),
            description = ('Raio %.1fm | %.2f, %.2f, %.2f'):format(removal.radius or 0.0, removal.coords.x, removal.coords.y, removal.coords.z),
            icon = 'eye-slash',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Apagar remocao?',
                    content = 'O objeto vanilla pode voltar quando a area recarregar.',
                    centered = true,
                    cancel = true
                })
                if confirm ~= 'confirm' then return end
                local result = lib.callback.await('cidade_tycoon_worldbuilder:server:deleteRemoval', false, removal.id)
                notify(result.message, result.ok and 'success' or 'error')
            end
        }
    end

    if #options == 0 then
        options[1] = { title = 'Nenhuma remocao salva', disabled = true }
    end

    lib.registerContext({
        id = 'cidade_worldbuilder_removals',
        title = 'Props do mapa ocultos',
        menu = 'cidade_worldbuilder_main',
        options = options
    })
    lib.showContext('cidade_worldbuilder_removals')
end

local function openMainMenu()
    if not isBuilder then
        notify('Sem permissao para construir.', 'error')
        return
    end

    local options = {
        {
            title = 'Colocar prop por modelo',
            icon = 'cube',
            onSelect = promptCustomProp
        }
    }

    for _, category in ipairs(config.presets) do
        options[#options + 1] = {
            title = category.label,
            icon = 'boxes-stacked',
            onSelect = function()
                openPresetCategory(category)
            end
        }
    end

    options[#options + 1] = {
        title = 'Editar prop salvo mais proximo',
        icon = 'pen-to-square',
        onSelect = editNearest
    }
    options[#options + 1] = {
        title = 'Mover prop/NPC existente na mira',
        description = 'Reposiciona entidades criadas por outros scripts.',
        icon = 'person-walking-arrow-right',
        onSelect = moveAimedExternal
    }
    options[#options + 1] = {
        title = 'Gerenciar entidades movidas',
        icon = 'list-check',
        onSelect = openExternalMenu
    }
    options[#options + 1] = {
        title = 'Ocultar prop original do mapa',
        description = 'Mire em um objeto vanilla antes de selecionar.',
        icon = 'eye-slash',
        onSelect = hideMapObject
    }
    options[#options + 1] = {
        title = 'Gerenciar props ocultos',
        icon = 'list',
        onSelect = openRemovalsMenu
    }
    options[#options + 1] = {
        title = 'Recarregar mundo',
        icon = 'rotate',
        onSelect = function()
            TriggerServerEvent('chat:addMessage', { args = { 'WorldBuilder', 'Use /wb_reload no console/admin.' } })
        end
    }

    lib.registerContext({
        id = 'cidade_worldbuilder_main',
        title = 'World Builder Tycoon',
        options = options
    })
    lib.showContext('cidade_worldbuilder_main')
end

RegisterNetEvent('cidade_tycoon_worldbuilder:client:syncWorld', function(newWorld)
    world = newWorld or { props = {}, removals = {}, externalEntities = {} }
    world.externalEntities = world.externalEntities or {}
    cleanupSpawned()
    cleanupExternalFallbacks()
    despawnFarProps()
    applyRemovals()
    if not placement or placement.mode ~= 'external' then
        applyExternalOverrides()
    end
end)

CreateThread(function()
    Wait(1500)
    local result, allowed = lib.callback.await('cidade_tycoon_worldbuilder:server:getWorld', false)
    world = result or { props = {}, removals = {}, externalEntities = {} }
    world.externalEntities = world.externalEntities or {}
    isBuilder = allowed == true

    while true do
        despawnFarProps()
        applyExternalOverrides()
        Wait(1500)
    end
end)

CreateThread(function()
    while true do
        applyRemovals()
        Wait(config.removalTickMs)
    end
end)

RegisterCommand(config.command, function()
    openMainMenu()
end, false)

RegisterCommand(config.propCommand, function(_, args)
    if not isBuilder then
        notify('Sem permissao para construir.', 'error')
        return
    end

    local model = args[1]
    if not model then
        promptCustomProp()
        return
    end

    startPlacement(model, args[2] or model)
end, false)

RegisterCommand('editprop', function()
    if not isBuilder then
        notify('Sem permissao para construir.', 'error')
        return
    end
    editNearest()
end, false)

RegisterCommand('hideprop', function()
    if not isBuilder then
        notify('Sem permissao para construir.', 'error')
        return
    end
    hideMapObject()
end, false)

RegisterCommand('moveentity', function()
    if not isBuilder then
        notify('Sem permissao para construir.', 'error')
        return
    end
    moveAimedExternal()
end, false)

RegisterCommand('entitiesmenu', function()
    if not isBuilder then
        notify('Sem permissao para construir.', 'error')
        return
    end
    openExternalMenu()
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    stopPlacement(true)
    cleanupSpawned()
    cleanupExternalFallbacks()
end)
