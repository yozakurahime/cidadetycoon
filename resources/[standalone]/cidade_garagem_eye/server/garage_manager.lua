-- server/garage_manager.lua
-- Dynamic garage management system
-- Stores custom garages in JSON and registers them with qbx_garages

local GARAGE_FILE = 'server/custom_garages.json'
local CustomGarages = {}

-- ==========================================
-- PERSISTENCE
-- ==========================================

local function loadCustomGarages()
    local content = LoadResourceFile(GetCurrentResourceName(), GARAGE_FILE)
    if content then
        local success, parsed = pcall(json.decode, content)
        if success and parsed then
            CustomGarages = parsed
        end
    end
    -- Register all loaded garages with qbx_garages
    for name, config in pairs(CustomGarages) do
        if GetResourceState('qbx_garages') == 'started' then
            exports.qbx_garages:RegisterGarage(name, config)
        end
    end
    local count = 0
    for _ in pairs(CustomGarages) do count = count + 1 end
    print(('^2[Tycoon:GarageManager]^7 %d garagens customizadas carregadas.'):format(count))
end

local function saveCustomGarages()
    SaveResourceFile(GetCurrentResourceName(), GARAGE_FILE, json.encode(CustomGarages, { indent = true }), -1)
end

-- ==========================================
-- GARAGE CRUD
-- ==========================================

local function generateGarageName(label)
    local base = label:lower():gsub('[^a-z0-9]', ''):sub(1, 20)
    local name = base
    local counter = 1
    while CustomGarages[name] or (exports.qbx_garages:GetGarages() or {})[name] do
        counter = counter + 1
        name = base .. tostring(counter)
    end
    return name
end

---Add a new custom garage
---@param source number
---@param label string Display name
---@param accessCoords vector4 Access point
---@param spawnCoords vector4 Spawn point
---@param vehicleType string 'car' | 'air' | 'sea'
---@param groups string|nil Job/gang restriction (nil = public)
---@param blipVisible boolean Show blip on map
---@return table { ok, message, name? }
local function addGarage(source, label, accessCoords, spawnCoords, vehicleType, groups, blipVisible)
    local name = generateGarageName(label)

    local garageConfig = {
        label = label,
        vehicleType = vehicleType or 'car',
        accessPoints = {
            {
                coords = accessCoords,
                spawn = spawnCoords,
            }
        },
    }

    -- Groups restriction
    if groups and groups ~= '' then
        garageConfig.groups = groups
    end

    -- Blip configuration
    if blipVisible ~= false then
        local blipNames = {
            car = 'Garagem',
            air = 'Hangar',
            sea = 'Garagem Nautica',
        }
        garageConfig.accessPoints[1].blip = {
            name = label,
            sprite = 357,
            color = 3,
        }
    end

    -- Save and register
    CustomGarages[name] = garageConfig
    saveCustomGarages()

    if GetResourceState('qbx_garages') == 'started' then
        exports.qbx_garages:RegisterGarage(name, garageConfig)
    end

    print(('^2[Tycoon:GarageManager]^7 Garagem %s criada por %d'):format(name, source))
    return { ok = true, message = ('Garagem %s criada com sucesso!'):format(label), name = name }
end

---Remove a custom garage
---@param name string
---@return table { ok, message }
local function removeGarage(name)
    if not CustomGarages[name] then
        return { ok = false, message = 'Garagem nao encontrada.' }
    end
    CustomGarages[name] = nil
    saveCustomGarages()

    -- Note: qbx_garages doesn't have a RemoveGarage export, so we just remove from our list
    -- The garage will still show until server restart
    return { ok = true, message = 'Garagem removida. Efetiva apos restart.' }
end

---List all custom garages
---@return table[]
local function listGarages()
    local list = {}
    for name, config in pairs(CustomGarages) do
        table.insert(list, {
            name = name,
            label = config.label,
            vehicleType = config.vehicleType,
            groups = config.groups or 'publico',
            hasBlip = config.accessPoints and config.accessPoints[1] and config.accessPoints[1].blip ~= nil,
            coords = config.accessPoints and config.accessPoints[1] and config.accessPoints[1].coords,
        })
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

---Update garage config
---@param name string
---@param updates table
---@return table { ok, message }
local function updateGarage(name, updates)
    if not CustomGarages[name] then
        return { ok = false, message = 'Garagem nao encontrada.' }
    end

    local config = CustomGarages[name]

    if updates.label then config.label = updates.label end
    if updates.vehicleType then config.vehicleType = updates.vehicleType end
    if updates.groups ~= nil then
        if updates.groups == '' then
            config.groups = nil
        else
            config.groups = updates.groups
        end
    end
    if updates.blipVisible ~= nil then
        if updates.blipVisible then
            config.accessPoints[1].blip = config.accessPoints[1].blip or {
                name = config.label,
                sprite = 357,
                color = 3,
            }
        else
            config.accessPoints[1].blip = nil
        end
    end
    if updates.accessCoords then
        config.accessPoints[1].coords = updates.accessCoords
    end
    if updates.spawnCoords then
        config.accessPoints[1].spawn = updates.spawnCoords
    end

    saveCustomGarages()

    -- Re-register with qbx_garages (overwrites existing)
    if GetResourceState('qbx_garages') == 'started' then
        exports.qbx_garages:RegisterGarage(name, config)
    end

    return { ok = true, message = ('Garagem %s atualizada!'):format(config.label) }
end

-- ==========================================
-- COMMAND HANDLERS (Server-side validation)
-- ==========================================

local activePositioning = {} -- [source] = { step, data }

local function hasAdminPermission(source)
    if IsPlayerAceAllowed(source, 'command') then return true end
    if exports.cidade_tycoon_core:HasPermission and exports.cidade_tycoon_core:HasPermission(source, 'admin') then return true end
    if exports.cidade_tycoon_core:HasPermission and exports.cidade_tycoon_core:HasPermission(source, 'god') then return true end
    return false
end

lib.callback.register('cidade_garagem_eye:server:addGarage', function(source, data)
    if not hasAdminPermission(source) then
        return { ok = false, message = 'Sem permissao.' }
    end
    return addGarage(source, data.label, data.accessCoords, data.spawnCoords, data.vehicleType, data.groups, data.blipVisible)
end)

lib.callback.register('cidade_garagem_eye:server:removeGarage', function(source, name)
    if not hasAdminPermission(source) then
        return { ok = false, message = 'Sem permissao.' }
    end
    return removeGarage(name)
end)

lib.callback.register('cidade_garagem_eye:server:listGarages', function(source)
    if not hasAdminPermission(source) then
        return {}
    end
    return listGarages()
end)

lib.callback.register('cidade_garagem_eye:server:updateGarage', function(source, name, updates)
    if not hasAdminPermission(source) then
        return { ok = false, message = 'Sem permissao.' }
    end
    return updateGarage(name, updates)
end)

-- ==========================================
-- INITIALIZATION
-- ==========================================

CreateThread(function()
    -- Wait for qbx_garages to be ready
    local attempts = 0
    while GetResourceState('qbx_garages') ~= 'started' and attempts < 50 do
        Wait(200)
        attempts = attempts + 1
    end
    loadCustomGarages()
end)

-- Export for other resources
exports('AddGarage', addGarage)
exports('RemoveGarage', removeGarage)
exports('ListCustomGarages', listGarages)
exports('UpdateGarage', updateGarage)
