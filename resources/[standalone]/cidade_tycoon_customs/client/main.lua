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
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local checkCoords = veh ~= 0 and GetEntityCoords(veh) or GetEntityCoords(ped)

    local customSpots = GlobalState['tycoon:customs_spots']
    if customSpots and #customSpots > 0 then
        for _, coords in ipairs(customSpots) do
            local spot = vec3(coords.x, coords.y, coords.z)
            if #(checkCoords - spot) < 3.0 then
                return true
            end
        end
    else
        for _, coords in ipairs(sharedConfig.Workshops) do
            if #(checkCoords - coords) < 3.0 then
                return true
            end
        end
    end
    return false
end

local function hasMechanicJob()
    local job = LocalPlayer.state.job or (exports.qbx_core:GetPlayerData() and exports.qbx_core:GetPlayerData().job)
    return job and job.name == 'mechanic'
end

local function normalizePlate(plate)
    return plate and tostring(plate):gsub('^%s*(.-)%s*$', '%1') or nil
end

local visualModTypes = {
    { key = 'modSpoilers', modType = 0, label = 'Spoiler' },
    { key = 'modFrontBumper', modType = 1, label = 'Parachoque Dianteiro' },
    { key = 'modRearBumper', modType = 2, label = 'Parachoque Traseiro' },
    { key = 'modSideSkirt', modType = 3, label = 'Saias Laterais' },
    { key = 'modExhaust', modType = 4, label = 'Escapamento' },
    { key = 'modFrame', modType = 5, label = 'Gaiola / Chassi' },
    { key = 'modGrille', modType = 6, label = 'Grade' },
    { key = 'modHood', modType = 7, label = 'Capo' },
    { key = 'modFender', modType = 8, label = 'Paralama Esquerdo' },
    { key = 'modRightFender', modType = 9, label = 'Paralama Direito' },
    { key = 'modRoof', modType = 10, label = 'Teto' },
    { key = 'modPlateHolder', modType = 25, label = 'Suporte de Placa' },
    { key = 'modVanityPlate', modType = 26, label = 'Placa Decorativa' },
    { key = 'modTrimA', modType = 27, label = 'Acabamento A' },
    { key = 'modOrnaments', modType = 28, label = 'Ornamentos' },
    { key = 'modDashboard', modType = 29, label = 'Painel' },
    { key = 'modDial', modType = 30, label = 'Mostradores' },
    { key = 'modDoorSpeaker', modType = 31, label = 'Alto-falante Porta' },
    { key = 'modSeats', modType = 32, label = 'Bancos' },
    { key = 'modSteeringWheel', modType = 33, label = 'Volante' },
    { key = 'modShifterLeavers', modType = 34, label = 'Cambio Interno' },
    { key = 'modAPlate', modType = 35, label = 'Placa A' },
    { key = 'modSpeakers', modType = 36, label = 'Som' },
    { key = 'modTrunk', modType = 37, label = 'Porta-malas' },
    { key = 'modHydrolic', modType = 38, label = 'Hidraulica' },
    { key = 'modEngineBlock', modType = 39, label = 'Bloco Visual' },
    { key = 'modAirFilter', modType = 40, label = 'Filtro de Ar Visual' },
    { key = 'modStruts', modType = 41, label = 'Struts' },
    { key = 'modArchCover', modType = 42, label = 'Cobertura de Arco' },
    { key = 'modAerials', modType = 43, label = 'Antenas' },
    { key = 'modTrimB', modType = 44, label = 'Acabamento B' },
    { key = 'modTank', modType = 45, label = 'Tanque' },
    { key = 'modWindows', modType = 46, label = 'Janelas' },
    { key = 'modDoorR', modType = 47, label = 'Porta Direita' },
    { key = 'modLivery', modType = 48, label = 'Livery' },
    { key = 'modLightbar', modType = 49, label = 'Lightbar' },
}

local function getAvailableVisualMods(vehicle)
    SetVehicleModKit(vehicle, 0)

    local mods = {}
    for _, def in ipairs(visualModTypes) do
        local count = GetNumVehicleMods(vehicle, def.modType)
        if count and count > 0 then
            mods[#mods + 1] = {
                key = def.key,
                modType = def.modType,
                label = def.label,
                count = count,
                current = GetVehicleMod(vehicle, def.modType)
            }
        end
    end

    local liveryCount = GetVehicleLiveryCount(vehicle)
    if liveryCount and liveryCount > 0 then
        mods[#mods + 1] = {
            key = 'livery',
            modType = -1,
            label = 'Livery',
            count = liveryCount,
            current = GetVehicleLivery(vehicle),
            kind = 'livery'
        }
    end

    return mods
end

local function getAvailableExtras(vehicle)
    local extras = {}
    for id = 1, 15 do
        if DoesExtraExist(vehicle, id) then
            extras[#extras + 1] = {
                id = id,
                enabled = IsVehicleExtraTurnedOn(vehicle, id)
            }
        end
    end
    return extras
end

local wheelCategories = {
    { id = 0, label = 'Sport' },
    { id = 1, label = 'Muscle' },
    { id = 2, label = 'Lowrider' },
    { id = 3, label = 'SUV' },
    { id = 4, label = 'Offroad' },
    { id = 5, label = 'Tuner' },
    { id = 6, label = 'Bike Wheels' },
    { id = 7, label = 'High End' },
    { id = 8, label = 'Bennys Original' },
    { id = 9, label = 'Bennys Custom' },
    { id = 10, label = 'Open Wheel' },
    { id = 11, label = 'Street' },
    { id = 12, label = 'Track' },
}

local function isWheelCategoryAllowed(vehicle, wheelType)
    local class = GetVehicleClass(vehicle)
    if class == 13 then return false end -- cycles
    if class == 8 then return wheelType == 6 end -- motorcycles
    if class == 22 then return wheelType == 10 end -- open wheel
    return wheelType ~= 6 and wheelType ~= 10
end

local function getAvailableWheelCategories(vehicle)
    SetVehicleModKit(vehicle, 0)

    local originalWheelType = GetVehicleWheelType(vehicle)
    local categories = {}

    for _, category in ipairs(wheelCategories) do
        if isWheelCategoryAllowed(vehicle, category.id) then
            SetVehicleWheelType(vehicle, category.id)
            local count = GetNumVehicleMods(vehicle, 23)
            if count and count > 0 then
                categories[#categories + 1] = {
                    id = category.id,
                    label = category.label,
                    count = count
                }
            end
        end
    end

    SetVehicleWheelType(vehicle, originalWheelType)
    return categories
end

local function requestVehicleControl(vehicle)
    if not NetworkGetEntityIsNetworked(vehicle) or NetworkGetEntityOwner(vehicle) == PlayerId() then
        return true
    end

    local timeout = GetGameTimer() + 750
    NetworkRequestControlOfEntity(vehicle)
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do
        Wait(0)
        NetworkRequestControlOfEntity(vehicle)
    end

    return NetworkHasControlOfEntity(vehicle)
end

local function resetSession()
    originalProps = nil
    currentVehicle = 0
    currentPlate = nil
    shoppingCart = {}
end

local function closeCustomsUi()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function revertCustomizationSession()
    if currentVehicle ~= 0 and DoesEntityExist(currentVehicle) and originalProps then
        requestVehicleControl(currentVehicle)
        SetVehicleModKit(currentVehicle, 0)
        lib.setVehicleProperties(currentVehicle, originalProps)
        Wait(100)
        if DoesEntityExist(currentVehicle) then
            SetVehicleModKit(currentVehicle, 0)
            lib.setVehicleProperties(currentVehicle, originalProps)
        end
    end
end

-- ==========================================
-- MENU OPEN
-- ==========================================

function OpenAestheticMenu()
    if not isNearWorkshop() then
        notifyCustoms('Você precisa estacionar o veículo sobre a marcação de customização para personalizar.', 'error')
        return
    end

    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        notifyCustoms('Entre no veículo primeiro.', 'error')
        return
    end

    currentVehicle = veh
    currentPlate = normalizePlate(GetVehicleNumberPlateText(veh))
    SetVehicleModKit(veh, 0)

    if not originalProps then
        originalProps = lib.getVehicleProperties(veh)
    end

    local modelName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
    if modelName == "NULL" then modelName = GetDisplayNameFromVehicleModel(GetEntityModel(veh)) end

    local wheelCount = GetNumVehicleMods(veh, 23)

    local isMechanic = hasMechanicJob()
    local playerData = exports.qbx_core:GetPlayerData()
    local charName = playerData and (playerData.charinfo.firstname .. " " .. playerData.charinfo.lastname) or "Mecânico"

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        plate = currentPlate,
        model = modelName,
        props = originalProps,
        prices = sharedConfig.Prices,
        wheelCount = wheelCount,
        wheelCategories = getAvailableWheelCategories(veh),
        visualMods = getAvailableVisualMods(veh),
        extras = getAvailableExtras(veh),
        isMechanic = isMechanic,
        mechanicName = charName
    })
end

-- ==========================================
-- NUI CALLBACKS
-- ==========================================

RegisterNUICallback('previewMod', function(data, cb)
    if not currentVehicle or currentVehicle == 0 then return cb('ok') end
    requestVehicleControl(currentVehicle)
    SetVehicleModKit(currentVehicle, 0)

    local modType = data.type
    local val = data.value or data.val

    if modType == 'primaryColor' then
        local color1, color2 = GetVehicleColours(currentVehicle)
        SetVehicleColours(currentVehicle, tonumber(val), color2)
    elseif modType == 'secondaryColor' then
        local color1, color2 = GetVehicleColours(currentVehicle)
        SetVehicleColours(currentVehicle, color1, tonumber(val))
    elseif modType == 'pearlescentColor' then
        local pearlescentColor, wheelColor = GetVehicleExtraColours(currentVehicle)
        SetVehicleExtraColours(currentVehicle, tonumber(val), wheelColor)
    elseif modType == 'wheelColor' then
        local pearlescentColor, wheelColor = GetVehicleExtraColours(currentVehicle)
        SetVehicleExtraColours(currentVehicle, pearlescentColor, tonumber(val))
    elseif modType == 'wheels' then
        local cat = tonumber(data.cat)
        local wheelIndex = tonumber(val)
        SetVehicleWheelType(currentVehicle, cat)
        Wait(0)
        SetVehicleMod(currentVehicle, 23, wheelIndex, false)
        if cat == 6 then
            SetVehicleMod(currentVehicle, 24, wheelIndex, false)
        end
        Wait(0)
        SetVehicleWheelType(currentVehicle, cat)
        SetVehicleMod(currentVehicle, 23, wheelIndex, false)
        if cat == 6 then
            SetVehicleMod(currentVehicle, 24, wheelIndex, false)
        end
        local newWheelCount = GetNumVehicleMods(currentVehicle, 23)
        cb({
            wheelCount = newWheelCount,
            wheelType = GetVehicleWheelType(currentVehicle),
            modFrontWheels = GetVehicleMod(currentVehicle, 23),
            modBackWheels = GetVehicleMod(currentVehicle, 24),
        })
        return
    elseif modType == 'visualMod' then
        local visualType = tonumber(data.modType)
        local modIndex = tonumber(val)
        if data.kind == 'livery' then
            SetVehicleLivery(currentVehicle, modIndex)
        elseif visualType then
            SetVehicleMod(currentVehicle, visualType, modIndex, false)
        end
    elseif modType == 'extra' then
        local extraId = tonumber(data.extraId)
        local enabled = not not data.enabled
        if extraId then
            SetVehicleExtra(currentVehicle, extraId, not enabled)
        end
    elseif modType == 'neonToggle' then
        local enabled = not not data.enabled
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(currentVehicle, i, enabled)
        end
    elseif modType == 'neonColor' then
        local r, g, b = tonumber(data.r), tonumber(data.g), tonumber(data.b)
        SetVehicleNeonLightsColour(currentVehicle, r, g, b)
    elseif modType == 'xenonColor' then
        local colorVal = tonumber(val)
        if colorVal == -1 or colorVal == 255 then
            ToggleVehicleMod(currentVehicle, 22, false)
        else
            ToggleVehicleMod(currentVehicle, 22, true)
            SetVehicleXenonLightsColor(currentVehicle, colorVal)
        end
    elseif modType == 'windowTint' then
        local tint = tonumber(val)
        SetVehicleWindowTint(currentVehicle, tint)
        Wait(0)
        SetVehicleWindowTint(currentVehicle, tint)
        cb({ windowTint = GetVehicleWindowTint(currentVehicle) })
        return
    elseif modType == 'wash' then
        SetVehicleDirtLevel(currentVehicle, 0.0)
    end

    cb('ok')
end)

RegisterNUICallback('checkout', function(data, cb)
    local cart = data.cart
    local props = lib.getVehicleProperties(currentVehicle)

    local res = lib.callback.await('cidade_tycoon_customs:server:checkout', false, currentPlate, props, cart)

    if res.ok then
        notifyCustoms(res.message, 'success')
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        resetSession()
        cb('ok')
    else
        notifyCustoms(res.message, 'error')
        cb('error')
    end
end)

RegisterNUICallback('billClient', function(data, cb)
    local targetId = tonumber(data.targetId)
    local cart = data.cart
    local fee = tonumber(data.fee) or 0
    local props = lib.getVehicleProperties(currentVehicle)

    local res = lib.callback.await('cidade_tycoon_customs:server:billClient', false, targetId, currentPlate, props, cart, fee)

    if res.ok then
        notifyCustoms(res.message, 'success')
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        resetSession()
        cb('ok')
    else
        notifyCustoms(res.message, 'error')
        cb('error')
    end
end)

RegisterNUICallback('createWorkOrder', function(data, cb)
    TriggerServerEvent('cidade_tycoon_customs:server:createWorkOrder', data)
    notifyCustoms('Ordem de serviço publicada no mural!', 'success')
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    revertCustomizationSession()
    closeCustomsUi()
    resetSession()
    cb('ok')
end)

RegisterNUICallback('toggleOriginal', function(data, cb)
    if not currentVehicle or currentVehicle == 0 or not originalProps then cb('ok') return end
    requestVehicleControl(currentVehicle)
    SetVehicleModKit(currentVehicle, 0)
    if data.active then
        -- Show original state
        lib.setVehicleProperties(currentVehicle, originalProps)
    end
    -- Restore is handled by JS re-sending all previewMod calls
    cb('ok')
end)

RegisterNUICallback('startCameraRotation', function(data, cb)
    SetNuiFocus(true, false)

    CreateThread(function()
        Wait(50)

        while IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24) or IsControlPressed(0, 25) or IsDisabledControlPressed(0, 25) do
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            Wait(0)
        end

        SetNuiFocus(true, true)
    end)

    cb('ok')
end)

-- ==========================================
-- CLIENT SIDE CALLS FOR PAYMENT APPROVAL
-- ==========================================

lib.callback.register('cidade_tycoon_customs:client:requestPaymentApproval', function(subtotal, fee, total, plate, items)
    local alert = lib.alertDialog({
        header = 'Ordem de Serviço - ' .. plate,
        content = ('**Resumo dos Serviços:**\n- %s\n\n**Subtotal:** R$%d\n**Taxa do Mecânico:** R$%d\n**Total Geral:** R$%d\n\nDeseja pagar e aplicar as modificações agora?'):format(table.concat(items, '\n- '), subtotal, fee, total),
        centered = true,
        cancel = true
    })
    return alert == 'confirm'
end)

-- ==========================================
-- WORKSHOP MONITOR (Guardian Rule)
-- ==========================================
CreateThread(function()
    while true do
        local wait = 1000
        if currentVehicle ~= 0 then
            wait = 500
            local ped = PlayerPedId()
            local playerVehicle = GetVehiclePedIsIn(ped, false)
            local leftVehicle = playerVehicle ~= currentVehicle

            if not isNearWorkshop() or leftVehicle then
                revertCustomizationSession()
                closeCustomsUi()
                resetSession()
                notifyCustoms('Customizacao cancelada. Alteracoes revertidas porque nao houve pagamento.', 'error')
            end
        end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    revertCustomizationSession()
    closeCustomsUi()
end)

-- ==========================================
-- KEYPRESS INTERACTION THREAD
-- ==========================================
CreateThread(function()
    local showingText = false
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            if hasMechanicJob() and isNearWorkshop() then
                wait = 0
                if not showingText then
                    lib.showTextUI('[E] - Abrir Customização', {
                        position = "right-center",
                        icon = "wrench"
                    })
                    showingText = true
                end
                if IsControlJustPressed(0, 38) then -- E key
                    lib.hideTextUI()
                    showingText = false
                    OpenAestheticMenu()
                    Wait(500)
                end
            else
                if showingText then
                    lib.hideTextUI()
                    showingText = false
                end
            end
        else
            if showingText then
                lib.hideTextUI()
                showingText = false
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent('cidade_tycoon_customs:client:applyPaidMods', function(plate, mods)
    local normalizedPlate = normalizePlate(plate)
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        if normalizePlate(GetVehicleNumberPlateText(veh)) == normalizedPlate then
            SetVehicleModKit(veh, 0)
            lib.setVehicleProperties(veh, mods)
            SetVehicleDirtLevel(veh, 0.0)
            break
        end
    end
end)

RegisterCommand('tycoon_customs', OpenAestheticMenu, false)
