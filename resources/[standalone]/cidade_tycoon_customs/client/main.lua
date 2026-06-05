local sharedConfig = require 'config.shared'
local function notifyCustoms(message, type)
    lib.notify({
        title = 'Customização Tycoon',
        description = message,
        type = type or 'inform',
    })
end

-- Full Aesthetic Menu
function OpenAestheticMenu()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        notifyCustoms('Você precisa estar dentro de um veículo para customizá-lo.', 'error')
        return
    end

    local plate = GetVehicleNumberPlateText(veh)
    local options = {
        {
            title = 'Pintura',
            description = 'Cores primária, secundária e perolado.',
            icon = 'fa-solid fa-palette',
            onSelect = function() OpenPaintMenu(veh, plate) end
        },
        {
            title = 'Rodas',
            description = 'Trocar design e cor dos aros.',
            icon = 'fa-solid fa-circle-dot',
            onSelect = function() OpenWheelsMenu(veh, plate) end
        },
        {
            title = 'Iluminação',
            description = 'Neon e Faróis Xenon.',
            icon = 'fa-solid fa-lightbulb',
            onSelect = function() OpenLightingMenu(veh, plate) end
        },
        {
            title = 'Vidros',
            description = 'Películas de insulfilm.',
            icon = 'fa-solid fa-window-maximize',
            onSelect = function() OpenWindowMenu(veh, plate) end
        }
    }

    lib.registerContext({
        id = 'tycoon_customs_main',
        title = 'Customização de Frota',
        options = options
    })
    lib.showContext('tycoon_customs_main')
end

-- PAINT MENU
function OpenPaintMenu(veh, plate)
    local options = {
        {
            title = 'Cor Primária',
            description = ('Custo: $%d'):format(sharedConfig.prices.primaryColor),
            onSelect = function()
                local input = lib.inputDialog('Cor Primária', { { type = 'number', label = 'ID (0-159)', min = 0, max = 159 } })
                if input then applyAndSave(veh, plate, 'primaryColor', sharedConfig.prices.primaryColor, { color1 = input[1] }) end
            end
        },
        {
            title = 'Cor Secundária',
            description = ('Custo: $%d'):format(sharedConfig.prices.secondaryColor),
            onSelect = function()
                local input = lib.inputDialog('Cor Secundária', { { type = 'number', label = 'ID (0-159)', min = 0, max = 159 } })
                if input then applyAndSave(veh, plate, 'secondaryColor', sharedConfig.prices.secondaryColor, { color2 = input[1] }) end
            end
        },
        {
            title = 'Perolado',
            description = ('Custo: $%d'):format(sharedConfig.prices.pearlescent),
            onSelect = function()
                local input = lib.inputDialog('Perolado', { { type = 'number', label = 'ID (0-159)', min = 0, max = 159 } })
                if input then applyAndSave(veh, plate, 'pearlescent', sharedConfig.prices.pearlescent, { pearlescentColor = input[1] }) end
            end
        },
        {
            title = 'Cor das Rodas',
            description = ('Custo: $%d'):format(sharedConfig.prices.wheelColor),
            onSelect = function()
                local input = lib.inputDialog('Cor das Rodas', { { type = 'number', label = 'ID (0-159)', min = 0, max = 159 } })
                if input then applyAndSave(veh, plate, 'wheelColor', sharedConfig.prices.wheelColor, { wheelColor = input[1] }) end
            end
        }
    }

    lib.registerContext({
        id = 'tycoon_customs_paint',
        title = 'Pintura de Veículo',
        menu = 'tycoon_customs_main',
        options = options
    })
    lib.showContext('tycoon_customs_paint')
end

-- LIGHTING MENU
function OpenLightingMenu(veh, plate)
    local options = {
        {
            title = 'Toggle Neon (Lado/Frente/Trás)',
            description = ('Custo: $%d'):format(sharedConfig.prices.neonToggle),
            onSelect = function()
                local props = lib.getVehicleProperties(veh)
                local newState = not props.neonEnabled[1]
                applyAndSave(veh, plate, 'neonToggle', sharedConfig.prices.neonToggle, { neonEnabled = {newState, newState, newState, newState} })
            end
        },
        {
            title = 'Cor do Neon (RGB)',
            description = ('Custo: $%d'):format(sharedConfig.prices.neonColor),
            onSelect = function()
                local input = lib.inputDialog('RGB Neon', {
                    { type = 'number', label = 'R', min = 0, max = 255, default = 255 },
                    { type = 'number', label = 'G', min = 0, max = 255, default = 255 },
                    { type = 'number', label = 'B', min = 0, max = 255, default = 255 }
                })
                if input then applyAndSave(veh, plate, 'neonColor', sharedConfig.prices.neonColor, { neonColor = {input[1], input[2], input[3]} }) end
            end
        },
        {
            title = 'Faróis Xenon',
            description = ('Custo: $%d'):format(sharedConfig.prices.xenonColor),
            onSelect = function()
                local input = lib.inputDialog('Cor Xenon', { { type = 'number', label = 'ID (0-13)', min = 0, max = 13 } })
                if input then applyAndSave(veh, plate, 'xenonColor', sharedConfig.prices.xenonColor, { modXenon = true, xenonColor = input[1] }) end
            end
        }
    }

    lib.registerContext({
        id = 'tycoon_customs_lighting',
        title = 'Iluminação e Efeitos',
        menu = 'tycoon_customs_main',
        options = options
    })
    lib.showContext('tycoon_customs_lighting')
end

-- WHEELS MENU
function OpenWheelsMenu(veh, plate)
    local options = {}
    for _, cat in ipairs(sharedConfig.wheelCategories) do
        table.insert(options, {
            title = cat.label,
            onSelect = function()
                OpenSpecificWheels(veh, plate, cat.id, cat.label)
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_customs_wheels_cat',
        title = 'Categorias de Rodas',
        menu = 'tycoon_customs_main',
        options = options
    })
    lib.showContext('tycoon_customs_wheels_cat')
end

function OpenSpecificWheels(veh, plate, wheelType, label)
    SetVehicleWheelType(veh, wheelType)
    local num = GetNumVehicleMods(veh, 23)
    local options = {}

    for i = -1, num do
        table.insert(options, {
            title = i == -1 and 'Original' or ('Roda #' .. i),
            onSelect = function()
                applyAndSave(veh, plate, 'wheels', sharedConfig.prices.wheels, { wheelType = wheelType, modFrontWheels = i })
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_customs_wheels_list',
        title = label,
        menu = 'tycoon_customs_wheels_cat',
        options = options
    })
    lib.showContext('tycoon_customs_wheels_list')
end

-- WINDOW MENU
function OpenWindowMenu(veh, plate)
    local tints = {
        { id = 0, label = 'Nenhum' },
        { id = 3, label = 'Claro' },
        { id = 2, label = 'Médio' },
        { id = 1, label = 'Escuro' },
        { id = 4, label = 'Limo' },
    }
    local options = {}
    for _, t in ipairs(tints) do
        table.insert(options, {
            title = t.label,
            onSelect = function()
                applyAndSave(veh, plate, 'windowTint', sharedConfig.prices.windowTint, { windowTint = t.id })
            end
        })
    end

    lib.registerContext({
        id = 'tycoon_customs_windows',
        title = 'Películas',
        menu = 'tycoon_customs_main',
        options = options
    })
    lib.showContext('tycoon_customs_windows')
end

-- Helper to apply locally and persist to DB
function applyAndSave(veh, plate, modType, price, tempProps)
    -- 1. Apply locally for preview/confirmation
    lib.setVehicleProperties(veh, tempProps)
    
    -- 2. Get full current state
    local fullProps = lib.getVehicleProperties(veh)
    
    -- 3. Request purchase and save
    local res = lib.callback.await('cidade_tycoon_customs:server:purchaseMod', false, plate, modType, price, fullProps)
    
    if res.ok then
        notifyCustoms(res.message, 'success')
    else
        -- Revert if payment failed
        -- This is tricky without a "revert" prop table, but usually failure means no money, 
        -- so we just notify and the next spawn will revert it from DB anyway.
        notifyCustoms(res.message, 'error')
    end
end

exports('OpenAestheticMenu', OpenAestheticMenu)

RegisterCommand('tycoon_customs', function()
    OpenAestheticMenu()
end, false)
