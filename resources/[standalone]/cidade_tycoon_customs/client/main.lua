local logisticsConfig = require '@cidade_tycoon_logistics/config/shared'
local sharedConfig = require 'config/shared'

local originalProps = nil
local currentVehicle = 0
local currentPlate = nil
local shoppingCart = {}

local function notifyCustoms(message, type)
    lib.notify({
        title = 'Customização Tycoon',
        description = message,
        type = type or 'inform',
    })
    if type == 'success' then
        PlaySoundFrontend(-1, "PURCHASE_ACK", "HUD_LIQUIPEDIA_SOUNDSET", 1)
    end
end

-- Helper: Check Proximity
local function isNearWorkshop()
    local pCoords = GetEntityCoords(PlayerPedId())
    for _, warehouse in pairs(logisticsConfig.warehouses) do
        local base = warehouse.autopartsCoords or warehouse.productionCoords
        if base and #(pCoords - vec3(base.x, base.y, base.z)) < sharedConfig.WorkshopDistance then
            return true
        end
    end
    return false
end

-- ==========================================
-- SHOPPING CART LOGIC
-- ==========================================

local function addToCart(modType)
    shoppingCart[modType] = true
end

local function calculateTotal()
    local total = 0
    local items = {}
    for mod, _ in pairs(shoppingCart) do
        local price = sharedConfig.Prices[mod] or 0
        total = total + price
        table.insert(items, mod)
    end
    return total, items
end

local function resetSession()
    originalProps = nil
    currentVehicle = 0
    currentPlate = nil
    shoppingCart = {}
end

-- ==========================================
-- MENUS
-- ==========================================

function OpenAestheticMenu()
    if not isNearWorkshop() then
        notifyCustoms('Você precisa estar em uma oficina para customizar veículos.', 'error')
        return
    end

    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        notifyCustoms('Entre no veículo primeiro.', 'error')
        return
    end

    currentVehicle = veh
    currentPlate = GetVehicleNumberPlateText(veh)
    
    if not originalProps then
        originalProps = lib.getVehicleProperties(veh)
    end

    local total, _ = calculateTotal()

    local options = {
        {
            title = 'Pintura',
            icon = 'fa-solid fa-palette',
            onSelect = function() OpenPaintMenu() end
        },
        {
            title = 'Rodas',
            icon = 'fa-solid fa-circle-dot',
            onSelect = function() OpenWheelsMenu() end
        },
        {
            title = 'Iluminação',
            icon = 'fa-solid fa-lightbulb',
            onSelect = function() OpenLightingMenu() end
        },
        {
            title = 'Vidros',
            icon = 'fa-solid fa-window-maximize',
            onSelect = function() OpenWindowMenu() end
        },
        {
            title = 'Lavagem Profissional',
            description = ('Custo: $%d'):format(sharedConfig.Prices.wash),
            icon = 'fa-solid fa-soap',
            onSelect = function()
                SetVehicleDirtLevel(currentVehicle, 0.0)
                addToCart('wash')
                OpenAestheticMenu()
            end
        },
        {
            title = '^2FINALIZAR E PAGAR^7',
            description = ('Total no carrinho: $%d'):format(total),
            icon = 'fa-solid fa-check',
            disabled = total == 0,
            onSelect = function() ConfirmPurchase() end
        },
        {
            title = '^1CANCELAR TUDO^7',
            description = 'Reverte as alterações estéticas.',
            icon = 'fa-solid fa-xmark',
            onSelect = function()
                lib.setVehicleProperties(currentVehicle, originalProps)
                resetSession()
                notifyCustoms('Alterações canceladas.', 'inform')
            end
        }
    }

    lib.registerContext({
        id = 'tycoon_customs_main',
        title = 'Customização de Frota',
        options = options,
        onExit = function()
            -- Optional: notify user they have unsaved changes
        end
    })
    lib.showContext('tycoon_customs_main')
end

-- Confirmation Logic
function ConfirmPurchase()
    local total, _ = calculateTotal()
    local props = lib.getVehicleProperties(currentVehicle)
    
    local res = lib.callback.await('cidade_tycoon_customs:server:checkout', false, currentPlate, props, shoppingCart)
    
    if res.ok then
        notifyCustoms(res.message, 'success')
        resetSession()
    else
        notifyCustoms(res.message, 'error')
    end
end

-- SUBMENUS (Updated for Preview Mode)

function OpenPaintMenu()
    local options = {
        {
            title = 'Cor Primária',
            onSelect = function()
                local input = lib.inputDialog('Cor Primária', { { type = 'number', label = 'ID (0-159)', min = 0, max = 159 } })
                if input then 
                    lib.setVehicleProperties(currentVehicle, { color1 = input[1] })
                    addToCart('primaryColor')
                    OpenPaintMenu()
                end
            end
        },
        {
            title = 'Cor Secundária',
            onSelect = function()
                local input = lib.inputDialog('Cor Secundária', { { type = 'number', label = 'ID (0-159)', min = 0, max = 159 } })
                if input then 
                    lib.setVehicleProperties(currentVehicle, { color2 = input[1] })
                    addToCart('secondaryColor')
                    OpenPaintMenu()
                end
            end
        },
        {
            title = 'Perolado',
            onSelect = function()
                local input = lib.inputDialog('Perolado', { { type = 'number', label = 'ID (0-159)', min = 0, max = 159 } })
                if input then 
                    lib.setVehicleProperties(currentVehicle, { pearlescentColor = input[1] })
                    addToCart('pearlescentColor')
                    OpenPaintMenu()
                end
            end
        },
        {
            title = 'Cor das Rodas',
            onSelect = function()
                local input = lib.inputDialog('Cor das Rodas', { { type = 'number', label = 'ID (0-159)', min = 0, max = 159 } })
                if input then 
                    lib.setVehicleProperties(currentVehicle, { wheelColor = input[1] })
                    addToCart('wheelColor')
                    OpenPaintMenu()
                end
            end
        }
    }
    lib.registerContext({ id = 'tycoon_customs_paint', title = 'Pintura', menu = 'tycoon_customs_main', options = options })
    lib.showContext('tycoon_customs_paint')
end

function OpenLightingMenu()
    local options = {
        {
            title = 'Toggle Neon',
            onSelect = function()
                local props = lib.getVehicleProperties(currentVehicle)
                local newState = not props.neonEnabled[1]
                lib.setVehicleProperties(currentVehicle, { neonEnabled = {newState, newState, newState, newState} })
                addToCart('neonToggle')
                OpenLightingMenu()
            end
        },
        {
            title = 'Cor do Neon (RGB)',
            onSelect = function()
                local input = lib.inputDialog('RGB Neon', {
                    { type = 'number', label = 'R', min = 0, max = 255 },
                    { type = 'number', label = 'G', min = 0, max = 255 },
                    { type = 'number', label = 'B', min = 0, max = 255 }
                })
                if input then 
                    lib.setVehicleProperties(currentVehicle, { neonColor = {input[1], input[2], input[3]} })
                    addToCart('neonColor')
                    OpenLightingMenu()
                end
            end
        },
        {
            title = 'Faróis Xenon',
            onSelect = function()
                local input = lib.inputDialog('Cor Xenon', { { type = 'number', label = 'ID (0-13)', min = 0, max = 13 } })
                if input then 
                    lib.setVehicleProperties(currentVehicle, { modXenon = true, xenonColor = input[1] })
                    addToCart('xenonColor')
                    OpenLightingMenu()
                end
            end
        }
    }
    lib.registerContext({ id = 'tycoon_customs_lighting', title = 'Iluminação', menu = 'tycoon_customs_main', options = options })
    lib.showContext('tycoon_customs_lighting')
end

function OpenWheelsMenu()
    local options = {}
    for _, cat in ipairs(sharedConfig.WheelCategories) do
        table.insert(options, {
            title = cat.label,
            onSelect = function()
                SetVehicleWheelType(currentVehicle, cat.id)
                local num = GetNumVehicleMods(currentVehicle, 23)
                local wheelOptions = {}
                for i = -1, num do
                    table.insert(wheelOptions, {
                        title = i == -1 and 'Original' or ('Roda #' .. i),
                        onSelect = function()
                            lib.setVehicleProperties(currentVehicle, { wheelType = cat.id, modFrontWheels = i })
                            addToCart('wheels')
                            OpenWheelsMenu()
                        end
                    })
                end
                lib.registerContext({ id = 'tycoon_customs_wheels_list', title = cat.label, menu = 'tycoon_customs_main', options = wheelOptions })
                lib.showContext('tycoon_customs_wheels_list')
            end
        })
    end
    lib.registerContext({ id = 'tycoon_customs_wheels_cat', title = 'Rodas', menu = 'tycoon_customs_main', options = options })
    lib.showContext('tycoon_customs_wheels_cat')
end

function OpenWindowMenu()
    local tints = { { id = 0, label = 'Nenhum' }, { id = 3, label = 'Claro' }, { id = 2, label = 'Médio' }, { id = 1, label = 'Escuro' }, { id = 4, label = 'Limo' } }
    local options = {}
    for _, t in ipairs(tints) do
        table.insert(options, {
            title = t.label,
            onSelect = function()
                lib.setVehicleProperties(currentVehicle, { windowTint = t.id })
                addToCart('windowTint')
                OpenWindowMenu()
            end
        })
    end
    lib.registerContext({ id = 'tycoon_customs_windows', title = 'Vidros', menu = 'tycoon_customs_main', options = options })
    lib.showContext('tycoon_customs_windows')
end

-- ==========================================
-- WORKSHOP MONITOR (Guardian Rule)
-- ==========================================
CreateThread(function()
    while true do
        local wait = 1000
        if currentVehicle ~= 0 then
            wait = 500
            if not isNearWorkshop() then
                lib.setVehicleProperties(currentVehicle, originalProps)
                resetSession()
                lib.hideContext()
                notifyCustoms('Você saiu da oficina. Alterações revertidas.', 'error')
            end
        end
        Wait(wait)
    end
end)

RegisterCommand('tycoon_customs', OpenAestheticMenu, false)
