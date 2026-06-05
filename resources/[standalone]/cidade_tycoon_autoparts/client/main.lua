local logisticsConfig = require '@cidade_tycoon_logistics/config/shared'

local spawnedProps = {}

local function notifyAutoParts(message, type)
    lib.notify({
        title = 'Auto Peças Tycoon',
        description = message,
        type = type or 'inform',
    })
end

-- 1. MECHANICAL SHELF
function OpenMechanicalShelf()
    local parts = { 'engine_block', 'transmission_gear', 'suspension_arm' }
    local options = {}

    for _, itemName in ipairs(parts) do
        local part = exports.cidade_tycoon_core:GetPartData(itemName)
        if part then
            table.insert(options, {
                title = part.label,
                description = ('Preço: $%d | Peso: %.1fkg'):format(part.price, part.weight / 1000),
                onSelect = function()
                    local res = lib.callback.await('cidade_tycoon_autoparts:server:purchasePart', false, itemName, 1)
                    notifyAutoParts(res.message, res.ok and 'success' or 'error')
                end
            })
        end
    end

    lib.registerContext({
        id = 'tycoon_autoparts_mechanical',
        title = 'Prateleira: Componentes Mecânicos',
        options = options
    })
    lib.showContext('tycoon_autoparts_mechanical')
end

-- 2. MAINTENANCE SHELF
function OpenMaintenanceShelf()
    local parts = { 'basic_repair_kit', 'brake_pads', 'truck_tire' }
    local options = {}

    for _, itemName in ipairs(parts) do
        local part = exports.cidade_tycoon_core:GetPartData(itemName)
        if part then
            table.insert(options, {
                title = part.label,
                description = ('Preço: $%d | Peso: %.1fkg'):format(part.price, part.weight / 1000),
                onSelect = function()
                    local res = lib.callback.await('cidade_tycoon_autoparts:server:purchasePart', false, itemName, 1)
                    notifyAutoParts(res.message, res.ok and 'success' or 'error')
                end
            })
        end
    end

    lib.registerContext({
        id = 'tycoon_autoparts_maintenance',
        title = 'Prateleira: Itens de Manutenção',
        options = options
    })
    lib.showContext('tycoon_autoparts_maintenance')
end

-- 3. RECYCLING STATION
function OpenRecyclingStation()
    local options = {
        {
            title = 'Reciclar Sucata Mecânica',
            description = 'Gera: 5x Minério de Metal para o galpão.',
            icon = 'recycle',
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_autoparts:server:recycleScrap', false, 'mechanical_scrap')
                notifyAutoParts(res.message, res.ok and 'success' or 'error')
            end
        },
        {
            title = 'Reciclar Sucata Eletrônica',
            description = 'Gera: 5x Componentes Eletrônicos para o galpão.',
            icon = 'microchip',
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_autoparts:server:recycleScrap', false, 'electronic_scrap')
                notifyAutoParts(res.message, res.ok and 'success' or 'error')
            end
        }
    }

    lib.registerContext({
        id = 'tycoon_autoparts_recycling',
        title = 'Estação de Reciclagem de Peças',
        options = options
    })
    lib.showContext('tycoon_autoparts_recycling')
end

-- SPAWN PHYSICAL PROPS AND ATTACH TARGETS
local function createPhysicalInteractionPoint(coords, modelName, label, icon, onSelectFunc, floatingText)
    local modelHash = type(modelName) == 'string' and GetHashKey(modelName) or modelName
    
    RequestModel(modelHash)
    local timer = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timer do
        Wait(100)
    end

    if not HasModelLoaded(modelHash) then
        print("^1[Tycoon:AutoParts] Falha ao carregar modelo: " .. tostring(modelName))
        return nil
    end
    
    local obj = CreateObject(modelHash, coords.x, coords.y, coords.z - 1.0, false, false, false)
    SetEntityHeading(obj, 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    
    exports.ox_target:addLocalEntity(obj, {
        {
            name = 'tycoon_obj_' .. tostring(obj),
            icon = icon,
            label = label,
            onSelect = onSelectFunc,
            distance = 2.5
        }
    })
    
    table.insert(spawnedProps, {
        entity = obj,
        text = floatingText or label,
    })
    return obj
end

CreateThread(function()
    Wait(3000)
    
    for id, warehouse in pairs(logisticsConfig.warehouses) do
        local base = warehouse.productionCoords
        if base then
            -- 1. Mechanical Shelf (Left)
            createPhysicalInteractionPoint(
                vec3(base.x - 2.5, base.y, base.z), 
                "prop_table_03", 
                'Prateleira: Componentes Pesados', 
                'fa-solid fa-engine', 
                OpenMechanicalShelf,
                "~y~Componentes Pesados~w~"
            )

            -- 2. Maintenance Shelf (Right)
            createPhysicalInteractionPoint(
                vec3(base.x + 2.5, base.y, base.z), 
                "prop_table_03b", 
                'Prateleira: Itens de Manutenção', 
                'fa-solid fa-wrench', 
                OpenMaintenanceShelf,
                "~b~Itens de Manutencao~w~"
            )

            -- 3. Recycling Bin (Back)
            createPhysicalInteractionPoint(
                vec3(base.x, base.y - 2.5, base.z), 
                "prop_bin_05a", 
                'Caçamba de Reciclagem (Sucata)', 
                'fa-solid fa-recycle', 
                OpenRecyclingStation,
                "~g~Reciclagem de Sucata~w~"
            )
        end
    end
end)

-- THREAD VISUAL: labels vinculados as entidades reais das prateleiras.
CreateThread(function()
    while true do
        local wait = 1500
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, prop in ipairs(spawnedProps) do
            if DoesEntityExist(prop.entity) then
                local coords = GetEntityCoords(prop.entity)
                local dist = #(playerCoords - coords)

                if dist < 15.0 then
                    wait = 0
                    render3DText(coords, prop.text)
                end
            end
        end

        Wait(wait)
    end
end)

function render3DText(coords, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z + 1.2)
    if onScreen then
        SetTextScale(0.32, 0.32)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 180)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, prop in ipairs(spawnedProps) do
        if DoesEntityExist(prop.entity) then DeleteEntity(prop.entity) end
    end
end)

exports('OpenAutoPartsShop', function()
    OpenMaintenanceShelf()
end)
