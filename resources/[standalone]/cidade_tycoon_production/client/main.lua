local logisticsConfig = require '@cidade_tycoon_logistics/config/shared'

local spawnedMachines = {}

local function notifyProduction(message, type)
    lib.notify({
        title = 'Produção Tycoon',
        description = message,
        type = type or 'inform',
    })
end

local function resolveWorldBuilderPlacement(modelHash, coords)
    if GetResourceState('cidade_tycoon_worldbuilder') ~= 'started' then return nil end

    local ok, placement = pcall(function()
        return exports['cidade_tycoon_worldbuilder']:ResolveExternalPlacement(modelHash, coords, 'object')
    end)

    if ok then return placement end
    return nil
end

-- MAIN PRODUCTION MENU
function OpenProductionManager()
    local dashboard = lib.callback.await('cidade_tycoon_logistics:server:getBusinessDashboard', false)
    if not dashboard or not dashboard.hasCompany then
        notifyProduction('Você precisa de uma empresa para gerenciar produção.', 'error')
        return
    end

    local options = {
        {
            title = 'Linhas de Produção',
            description = 'Processar insumos e criar mercadorias.',
            icon = 'fa-solid fa-industry',
            onSelect = function() OpenRecipeMenu() end
        },
        {
            title = 'Inventário do Galpão',
            description = 'Ver insumos e produtos armazenados.',
            icon = 'fa-solid fa-warehouse',
            onSelect = function() OpenWarehouseInventory() end
        },
        {
            title = 'Comprar Insumos',
            description = 'Adquirir matérias-primas via caixa da empresa.',
            icon = 'fa-solid fa-cart-shopping',
            onSelect = function() OpenMaterialShop() end
        }
    }

    lib.registerContext({
        id = 'tycoon_production_main',
        title = 'Gestão Industrial: ' .. dashboard.company.name,
        options = options
    })
    lib.showContext('tycoon_production_main')
end

-- RECIPE SELECTION
function OpenRecipeMenu()
    local recipes = logisticsConfig.production.recipes
    local options = {}

    for key, recipe in pairs(recipes) do
        local inputStr = ""
        for item, qty in pairs(recipe.inputs) do
            local label = logisticsConfig.production.materials[item] and logisticsConfig.production.materials[item].label or item
            inputStr = inputStr .. ("%dx %s "):format(qty, label)
        end

        table.insert(options, {
            title = recipe.label,
            description = ('Requer: %s\nTempo: %d mins'):format(inputStr, math.floor(recipe.time / 60)),
            metadata = { { label = 'Categoria', value = recipe.category } },
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_production:server:startProduction', false, key)
                notifyProduction(res.message, res.ok and 'success' or 'error')
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_production_recipes',
        title = 'Receitas Industriais',
        menu = 'tycoon_production_main',
        options = options
    })
    lib.showContext('tycoon_production_recipes')
end

-- WAREHOUSE INVENTORY
function OpenWarehouseInventory()
    local inventory = lib.callback.await('cidade_tycoon_production:server:getWarehouseInventory', false)
    local options = {}

    if #inventory == 0 then
        options[#options + 1] = { title = 'Estoque Vazio', disabled = true }
    else
        for _, item in ipairs(inventory) do
            local label = logisticsConfig.production.materials[item.item_key] and logisticsConfig.production.materials[item.item_key].label
            if not label then
                local recipe = logisticsConfig.production.recipes[item.item_key]
                label = recipe and recipe.label or item.item_key
            end

            table.insert(options, {
                title = label,
                description = ('Quantidade: %d unidades'):format(item.amount),
                icon = 'fa-solid fa-box-open'
            })
        end
    end

    lib.registerContext({
        id = 'tycoon_production_inventory',
        title = 'Estoque do Galpão',
        menu = 'tycoon_production_main',
        options = options
    })
    lib.showContext('tycoon_production_inventory')
end

-- MATERIAL SHOP
function OpenMaterialShop()
    local materials = logisticsConfig.production.materials
    local options = {}

    for key, mat in pairs(materials) do
        table.insert(options, {
            title = mat.label,
            description = ('Preço unitário: $%d (Cobrado do cofre)'):format(mat.price),
            onSelect = function()
                local input = lib.inputDialog('Comprar Insumos', {
                    { type = 'number', label = 'Quantidade', default = 10, min = 1, max = 100 }
                })
                if input then
                    local res = lib.callback.await('cidade_tycoon_production:server:buyMaterials', false, key, input[1])
                    notifyProduction(res.message, res.ok and 'success' or 'error')
                end
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_production_materials',
        title = 'Mercado de Insumos',
        menu = 'tycoon_production_main',
        options = options
    })
    lib.showContext('tycoon_production_materials')
end

-- SPAWN INTERACTION MACHINES (Physical Benches)
CreateThread(function()
    Wait(4000)
    
    for id, warehouse in pairs(logisticsConfig.warehouses) do
        local coords = warehouse.productionCoords
        if coords then
            local modelName = "prop_toolchest_01"
            local modelHash = GetHashKey(modelName)
            
            RequestModel(modelHash)
            local timer = GetGameTimer() + 5000
            while not HasModelLoaded(modelHash) and GetGameTimer() < timer do
                Wait(100)
            end

            if HasModelLoaded(modelHash) then
                local defaultCoords = vec3(coords.x, coords.y, coords.z - 1.0)
                local placement = resolveWorldBuilderPlacement(modelHash, defaultCoords)
                local spawnCoords = placement and placement.coords or defaultCoords
                local obj = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)

                if placement and placement.rotation then
                    SetEntityRotation(obj, placement.rotation.x or 0.0, placement.rotation.y or 0.0, placement.rotation.z or placement.heading or 0.0, 2, true)
                    SetEntityHeading(obj, placement.heading or placement.rotation.z or 180.0)
                else
                    SetEntityHeading(obj, 180.0)
                end

                FreezeEntityPosition(obj, true)
                SetEntityInvincible(obj, true)
                
                exports.ox_target:addLocalEntity(obj, {
                    {
                        name = 'tycoon_prod_bench_' .. tostring(obj),
                        icon = 'fa-solid fa-industry',
                        label = 'Painel de Controle Industrial',
                        onSelect = function()
                            OpenProductionManager()
                        end,
                        distance = 2.5
                    }
                })
                
                table.insert(spawnedMachines, {
                    entity = obj,
                    text = "~o~Terminal de Producao~w~",
                })
            end
        end
    end
end)

-- THREAD VISUAL: labels vinculados as entidades reais dos terminais.
CreateThread(function()
    while true do
        local wait = 1500
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, machine in ipairs(spawnedMachines) do
            if DoesEntityExist(machine.entity) then
                local coords = GetEntityCoords(machine.entity)
                local dist = #(playerCoords - coords)

                if dist < 12.0 then
                    wait = 0
                    render3DText(coords, machine.text)
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
    for _, machine in ipairs(spawnedMachines) do
        if DoesEntityExist(machine.entity) then DeleteEntity(machine.entity) end
    end
end)

exports('OpenProductionManager', OpenProductionManager)
