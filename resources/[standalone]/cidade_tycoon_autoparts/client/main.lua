local spawnedProps = {}
local npcEntity = nil

local Config = require 'config'

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

---------------------------------------------------------------------------
-- UI DA LOJA DE PEÇAS (NPC)
---------------------------------------------------------------------------

function OpenPurchaseDialog(itemName, partData)
    local input = lib.inputDialog('Comprar ' .. partData.label, {
        {
            type = 'number',
            label = 'Quantidade',
            description = 'Máximo de ' .. Config.MaxPurchasePerTurn .. ' por vez.',
            icon = 'hashtag',
            default = 1,
            min = 1,
            max = Config.MaxPurchasePerTurn
        }
    })

    if not input then return end
    local amount = input[1]

    local res = lib.callback.await('cidade_tycoon_autoparts:server:purchasePart', false, itemName, amount)
    notifyAutoParts(res.message, res.ok and 'success' or 'error')
end

function OpenCategoryMenu(category)
    local options = {}

    for _, itemName in ipairs(category.items) do
        local part = exports.cidade_tycoon_core:GetPartData(itemName)
        if part then
            table.insert(options, {
                title = part.label,
                description = ('Preço: $%d | Peso: %.1fkg'):format(part.price, part.weight / 1000),
                image = "nui://ox_inventory/web/images/" .. itemName .. ".png", -- Imagem linda do ox_inventory
                icon = 'box',
                onSelect = function()
                    OpenPurchaseDialog(itemName, part)
                end
            })
        end
    end

    lib.registerContext({
        id = 'tycoon_autoparts_category_' .. category.id,
        title = category.title,
        menu = 'tycoon_autoparts_main',
        options = options
    })
    lib.showContext('tycoon_autoparts_category_' .. category.id)
end

function OpenAutoPartsMain()
    local options = {}

    for _, cat in ipairs(Config.ShopCategories) do
        table.insert(options, {
            title = cat.title,
            description = cat.description,
            icon = cat.icon,
            onSelect = function()
                OpenCategoryMenu(cat)
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_autoparts_main',
        title = 'Catálogo de Peças Tycoon',
        options = options
    })
    lib.showContext('tycoon_autoparts_main')
end

---------------------------------------------------------------------------
-- ESTAÇÃO DE RECICLAGEM
---------------------------------------------------------------------------

function OpenRecyclingStation()
    local options = {}
    for _, opt in ipairs(Config.Recycling.options) do
        table.insert(options, {
            title = opt.title,
            description = ('Gera: %dx %s para o armazém da empresa.'):format(opt.amount, opt.reward),
            icon = opt.icon,
            image = "nui://ox_inventory/web/images/" .. opt.item .. ".png",
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

---------------------------------------------------------------------------
-- SPAWN DE ENTIDADES (NPC e LIXEIRAS)
---------------------------------------------------------------------------

local function createNpc()
    print("[Tycoon:AutoParts] Starting createNpc...")
    local modelHash = GetHashKey(Config.NPC.model)

    RequestModel(modelHash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeout do
        Wait(100)
    end

    if not HasModelLoaded(modelHash) then
        print("^1[Tycoon:AutoParts] ERROR: Failed to load NPC model: " .. tostring(Config.NPC.model) .. "^7")
        return
    end

    local heading = Config.NPC.heading or (Config.NPC.coords.w or 0.0)
    print("[Tycoon:AutoParts] Spawning ped at X: " .. Config.NPC.coords.x .. " Y: " .. Config.NPC.coords.y .. " Z: " .. Config.NPC.coords.z)

    npcEntity = CreatePed(4, modelHash, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, heading, false, false)
    SetEntityHeading(npcEntity, heading)
    FreezeEntityPosition(npcEntity, true)
    SetEntityInvincible(npcEntity, true)
    SetBlockingOfNonTemporaryEvents(npcEntity, true)
    TaskStartScenarioInPlace(npcEntity, Config.NPC.scenario, 0, true)

    exports.ox_target:addLocalEntity(npcEntity, {
        {
            name = 'tycoon_autoparts_npc',
            icon = 'fa-solid fa-cart-shopping',
            label = 'Falar com Vendedor de Peças',
            onSelect = OpenAutoPartsMain,
            distance = 2.5
        }
    })

    -- Criar Blip
    local blip = AddBlipForCoord(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z)
    SetBlipSprite(blip, Config.NPC.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.NPC.blip.scale)
    SetBlipColour(blip, Config.NPC.blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.NPC.blip.label)
    EndTextCommandSetBlipName(blip)

    SetModelAsNoLongerNeeded(modelHash)
    print("[Tycoon:AutoParts] NPC spawned successfully!")
end

local function createPhysicalInteractionPoint(coords, modelName, label, icon, onSelectFunc, floatingText)
    local modelHash = GetHashKey(modelName)

    RequestModel(modelHash)
    local timer = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timer do
        Wait(100)
    end

    if not HasModelLoaded(modelHash) then return nil end

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
    Wait(2000)

    -- 1. Spawn NPC na Concessionária
    createNpc()

    -- 2. Spawn Lixeiras de Reciclagem nos Galpões
    if Config.WarehouseLocations then
        for _, base in ipairs(Config.WarehouseLocations) do
            createPhysicalInteractionPoint(
                vec3(base.x, base.y - 2.5, base.z),
                "prop_ld_bin_01",
                Config.Recycling.label,
                "fa-solid fa-" .. Config.Recycling.icon,
                OpenRecyclingStation,
                Config.Recycling.color .. Config.Recycling.label
            )
        end
    end
end)

-- THREAD VISUAL: Textos flutuantes (apenas para as lixeiras agora)
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

    if DoesEntityExist(npcEntity) then DeleteEntity(npcEntity) end

    for _, prop in ipairs(spawnedProps) do
        if DoesEntityExist(prop.entity) then DeleteEntity(prop.entity) end
    end
end)

exports('OpenAutoPartsShop', OpenAutoPartsMain)
