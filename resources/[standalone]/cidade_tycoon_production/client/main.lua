local logisticsConfig = require '@cidade_tycoon_logistics/config/shared'
local spawnedMachines = {}

local function notifyProduction(message, type)
    lib.notify({
        title = 'Produção Tycoon',
        description = message,
        type = type or 'inform',
    })
    if type == 'success' then PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", 1) end
end

-- ==========================================
-- PRODUCTION INTERFACE
-- ==========================================

function OpenProductionManager()
    local options = {
        {
            title = 'Iniciar Produção',
            description = 'Processar matérias-primas e sucata.',
            icon = 'industry',
            onSelect = function() OpenRecipeMenu() end
        },
        {
            title = 'Inventário do Galpão',
            description = 'Gerir estoque industrial.',
            icon = 'warehouse',
            onSelect = function() OpenWarehouseInventory() end
        }
    }

    lib.registerContext({ id = 'tycoon_prod_main', title = 'Terminal Industrial', options = options })
    lib.showContext('tycoon_prod_main')
end

function OpenRecipeMenu()
    local recipes = logisticsConfig.Production.Recipes
    local options = {}

    for key, recipe in pairs(recipes) do
        local inputStr = ""
        for item, qty in pairs(recipe.inputs) do
            local label = logisticsConfig.Production.Materials[item] and logisticsConfig.Production.Materials[item].label or item
            inputStr = inputStr .. ("%dx %s "):format(qty, label)
        end

        table.insert(options, {
            title = recipe.label,
            description = ('Requer: %s\nTempo: %d mins'):format(inputStr, math.floor(recipe.time / 60)),
            onSelect = function()
                local res = lib.callback.await('cidade_tycoon_production:server:startProduction', false, key)
                notifyProduction(res.message, res.ok and 'success' or 'error')
            end
        })
    end

    lib.registerContext({ id = 'tycoon_prod_recipes', title = 'Receitas', menu = 'tycoon_prod_main', options = options })
    lib.showContext('tycoon_prod_recipes')
end

function OpenWarehouseInventory()
    local inventory = lib.callback.await('cidade_tycoon_production:server:getWarehouseInventory', false)
    local options = {}

    if #inventory == 0 then
        table.insert(options, { title = 'Estoque Vazio', disabled = true })
    else
        for _, item in ipairs(inventory) do
            local label = logisticsConfig.Production.Materials[item.item_key] and logisticsConfig.Production.Materials[item.item_key].label
            if not label then
                local recipe = logisticsConfig.Production.Recipes[item.item_key]
                label = recipe and recipe.label or item.item_key
            end

            table.insert(options, {
                title = label,
                description = ('Estoque: %d unidades'):format(item.amount),
                icon = 'box'
            })
        end
    end

    lib.registerContext({ id = 'tycoon_prod_inventory', title = 'Almoxarifado', menu = 'tycoon_prod_main', options = options })
    lib.showContext('tycoon_prod_inventory')
end

-- ==========================================
-- PHYSICAL TERMINALS (ox_lib Points)
-- ==========================================
CreateThread(function()
    Wait(4000)
    
    if not logisticsConfig or not logisticsConfig.warehouses then
        print("^1[Tycoon:Production]^7 ERRO: Tabela de galpões não encontrada no shared config.")
        return
    end

    for _, warehouse in pairs(logisticsConfig.warehouses) do
        local base = warehouse.productionCoords
        if base then
            local terminalPoint = lib.points.new({
                coords = vec3(base.x, base.y, base.z),
                distance = 15.0
            })

            function terminalPoint:onEnter()
                local model = joaat("prop_toolchest_01")
                lib.requestModel(model)
                local obj = CreateObject(model, self.coords.x, self.coords.y, self.coords.z - 1.0, false, false, false)
                SetEntityHeading(obj, 180.0)
                FreezeEntityPosition(obj, true)
                SetEntityInvincible(obj, true)

                exports.ox_target:addLocalEntity(obj, {
                    {
                        name = 'tycoon_prod_terminal_' .. tostring(obj),
                        icon = 'fa-solid fa-microchip',
                        label = 'Painel Industrial',
                        onSelect = function() OpenProductionManager() end,
                        distance = 2.0
                    }
                })
                self.entity = obj
            end

            function terminalPoint:nearby()
                if self.currentDistance < 12.0 then
                    DrawMarker(2, self.coords.x, self.coords.y, self.coords.z + 1.2, 0, 0, 0, 180.0, 0, 0, 0.3, 0.3, 0.3, 226, 179, 90, 150, true, true, 2, false)
                end
            end

            function terminalPoint:onExit()
                if self.entity and DoesEntityExist(self.entity) then
                    DeleteEntity(self.entity)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    lib.hideContext()
end)
