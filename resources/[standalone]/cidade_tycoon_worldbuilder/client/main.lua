local config = WorldBuilder.Config

local world = { props = {}, removals = {} }
local isBuilder = false
local spawned = {}
local targetNames = {}
local placement = nil

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
    local entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityRotation(entity, prop.rotation.x or 0.0, prop.rotation.y or 0.0, prop.rotation.z or prop.heading or 0.0, 2, true)
    SetEntityHeading(entity, prop.heading or prop.rotation.z or 0.0)
    FreezeEntityPosition(entity, prop.frozen ~= false)
    SetEntityCollision(entity, prop.collision ~= false, true)
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

local function cameraRay(distance)
    local camRot = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local pitch = math.rad(camRot.x)
    local yaw = math.rad(camRot.z)
    local direction = vec3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
    local destination = camCoord + direction * distance
    local ray = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0)
    local _, hit, endCoords, _, entity = GetShapeTestResult(ray)
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

local function drawHelpText(lines)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(table.concat(lines, '~n~'))
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function stopPlacement(deletePreview)
    if placement and placement.entity and DoesEntityExist(placement.entity) and deletePreview then
        DeleteEntity(placement.entity)
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

local function savePlacement()
    if not placement or not DoesEntityExist(placement.entity) then return end

    local payload = placementPayload(placement.entity, placement.model, placement.label, placement.existingId)
    local result
    if placement.existingId then
        result = lib.callback.await('cidade_tycoon_worldbuilder:server:updateProp', false, placement.existingId, payload)
    else
        result = lib.callback.await('cidade_tycoon_worldbuilder:server:addProp', false, payload)
    end

    notify(result.message or 'Salvo.', result.ok and 'success' or 'error')
    stopPlacement(true)
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
                stopPlacement(true)
            end

            local hit, endCoords = cameraRay(placement.distance)
            local coords = hit and endCoords or (GetEntityCoords(PlayerPedId()) + GetEntityForwardVector(PlayerPedId()) * placement.distance)
            coords = vec3(coords.x, coords.y, coords.z + placement.zOffset)

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
                'G: grudar no chao',
                'ENTER: salvar | BACKSPACE: cancelar'
            })
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
    world = newWorld or { props = {}, removals = {} }
    cleanupSpawned()
    despawnFarProps()
    applyRemovals()
end)

CreateThread(function()
    Wait(1500)
    local result, allowed = lib.callback.await('cidade_tycoon_worldbuilder:server:getWorld', false)
    world = result or { props = {}, removals = {} }
    isBuilder = allowed == true

    while true do
        despawnFarProps()
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

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    stopPlacement(true)
    cleanupSpawned()
end)
