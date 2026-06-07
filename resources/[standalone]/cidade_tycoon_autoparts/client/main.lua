local logisticsConfig = require '@cidade_tycoon_logistics/config/shared'

local spawnedProps = {}

local function notifyAutoParts(message, type)
    lib.notify({
        title = 'Auto Peças Tycoon',
        description = message,
        type = type or 'inform',
    })
    if type == 'success' then
        PlaySoundFrontend(-1, "PURCHASE_ACK", "HUD_LIQUIPEDIA_SOUNDSET", 1)
    end
end

-- 1. DYNAMIC SHELF OPENER
function OpenShelfMenu(shelfKey)
    local shelf = Config.Shelves[shelfKey]
    if not shelf then return end

    local options = {}
    for _, itemName in ipairs(shelf.items) do
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
        id = 'tycoon_autoparts_' .. shelfKey,
        title = shelf.title,
        options = options
    })
    lib.showContext('tycoon_autoparts_' .. shelfKey)
end

-- 2. RECYCLING STATION
function OpenRecyclingStation()
    local options = {}
    for _, opt in ipairs(Config.Recycling.options) do
        table.insert(options, {
            title = opt.title,
            description = ('Gera: %dx %s para o galpão.'):format(opt.amount, opt.reward),
            icon = opt.icon,
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_autoparts:server:recycleScrap', false, opt.item)
                notifyAutoParts(res.message, res.ok and 'success' or 'error')
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_autoparts_recycling',
        title = Config.Recycling.title,
        options = options
    })
    lib.showContext('tycoon_autoparts_recycling')
end

-- SPAWN PHYSICAL PROPS AND ATTACH TARGETS
local function createPhysicalInteractionPoint(coords, modelName, label, icon, onSelectFunc, floatingText)
    local modelHash = GetHashKey(modelName)
    
    if not IsModelInCdimage(modelHash) then return nil end

    RequestModel(modelHash)
    local timer = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timer do
        Wait(100)
    end

    if not HasModelLoaded(modelHash) then
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
    SetModelAsNoLongerNeeded(modelHash)
    return obj
end

CreateThread(function()
    Wait(3000)
    
    if not logisticsConfig or not logisticsConfig.warehouses then
        print("^1[Tycoon:AutoParts]^7 ERRO: Tabela de galpões não encontrada no shared config.")
        return
    end
    
    for id, warehouse in pairs(logisticsConfig.warehouses) do
        local base = warehouse.productionCoords
        if base then
            -- 1. Mechanical Shelf (Left)
            createPhysicalInteractionPoint(
                vec3(base.x - 2.5, base.y, base.z), 
                "prop_table_03", 
                Config.Shelves['mechanical'].label, 
                Config.Shelves['mechanical'].icon, 
                function() OpenShelfMenu('mechanical') end,
                Config.Shelves['mechanical'].color .. Config.Shelves['mechanical'].label
            )

            -- 2. Maintenance Shelf (Right)
            createPhysicalInteractionPoint(
                vec3(base.x + 2.5, base.y, base.z), 
                "prop_table_03b", 
                Config.Shelves['maintenance'].label, 
                Config.Shelves['maintenance'].icon, 
                function() OpenShelfMenu('maintenance') end,
                Config.Shelves['maintenance'].color .. Config.Shelves['maintenance'].label
            )

            -- 3. Recycling Bin (Back)
            createPhysicalInteractionPoint(
                vec3(base.x, base.y - 2.5, base.z), 
                "prop_ld_bin_01", 
                Config.Recycling.label, 
                Config.Recycling.icon, 
                OpenRecyclingStation,
                Config.Recycling.color .. Config.Recycling.label
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

                if dist < 12.0 then
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
    OpenShelfMenu('maintenance')
end)
