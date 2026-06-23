-- server/tools.lua

local Config = require 'config'

local function normalizePlate(plate)
    return exports.cidade_tycoon_core:NormalizePlate(plate)
end

local function plateMatches(vehicle, plate)
    return normalizePlate(GetVehicleNumberPlateText(vehicle)) == normalizePlate(plate)
end

local function playerNearVehicleWithPlate(source, plate, maxDistance)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local playerCoords = GetEntityCoords(ped)
    for _, vehicle in ipairs(GetAllVehicles()) do
        if plateMatches(vehicle, plate) then
            local vehicleCoords = GetEntityCoords(vehicle)
            if #(playerCoords - vehicleCoords) <= (maxDistance or 5.0) then
                return true
            end
        end
    end
    return false
end

local function getMechanicsOnline()
    local count = 0
    local players = GetPlayers()
    for _, src in ipairs(players) do
        local job = exports.cidade_tycoon_core:GetPlayerJob(tonumber(src))
        if job and job.name == 'mechanic' then
            count = count + 1
        end
    end
    return count
end

exports('GetMechanicsOnline', getMechanicsOnline)

lib.callback.register('cidade_tycoon_mechanic:server:getMechanicsOnline', function()
    return getMechanicsOnline()
end)

local activeCarJacks = {}

local function releaseCarJack(source, plate)
    plate = normalizePlate(tostring(plate or ''))
    local active = activeCarJacks[plate]

    if active and active.source == source then
        activeCarJacks[plate] = nil
    end
end

lib.callback.register('cidade_tycoon_mechanic:server:tryLockCarJack', function(source, plate, wheelName)
    plate = normalizePlate(tostring(plate or ''))

    if plate == '' then
        return { ok = false, message = 'Placa invalida para instalar o macaco.' }
    end

    if not playerNearVehicleWithPlate(source, plate, 6.0) then
        return { ok = false, message = 'Aproxime-se do veiculo para instalar o macaco.' }
    end

    local active = activeCarJacks[plate]
    if active and active.source ~= source then
        return { ok = false, message = 'Este veiculo ja esta levantado por outro jogador.' }
    end

    activeCarJacks[plate] = {
        source = source,
        wheelName = tostring(wheelName or ''),
        updatedAt = os.time(),
    }

    return { ok = true }
end)

lib.callback.register('cidade_tycoon_mechanic:server:releaseCarJack', function(source, plate)
    releaseCarJack(source, plate)
    return { ok = true }
end)

RegisterNetEvent('cidade_tycoon_mechanic:server:releaseCarJack', function(plate)
    releaseCarJack(source, plate)
end)

AddEventHandler('playerDropped', function()
    local dropped = source

    for plate, active in pairs(activeCarJacks) do
        if active.source == dropped then
            activeCarJacks[plate] = nil
        end
    end
end)

-- Register usable tools
CreateThread(function()
    Wait(2000) -- Wait a bit for initial framework startup
    local registered = false
    for i = 1, 10 do
        local status, err = pcall(function()
            exports.cidade_tycoon_core:CreateUseableItem('car_jack', function(source, item)
                print("[Tycoon:Mechanic] Player " .. source .. " used car_jack.")
                TriggerClientEvent('cidade_tycoon_mechanic:client:useCarJack', source)
            end)
        end)
        if status then
            print("[Tycoon:Mechanic] Successfully registered car_jack as usable item.")
            registered = true
            break
        else
            print("[Tycoon:Mechanic] Failed to register car_jack, retrying in 2s... Error: " .. tostring(err))
            Wait(2000)
        end
    end
    if not registered then
        print("[Tycoon:Mechanic] CRITICAL: Could not register car_jack usable item after retries.")
    end
end)

lib.callback.register('cidade_tycoon_mechanic:server:fixVehicleEmergency', function(source, plate, partType)
    plate = normalizePlate(plate)
    if not playerNearVehicleWithPlate(source, plate, 5.0) then
        return { ok = false, message = 'Aproxime-se do veiculo para fazer o reparo de emergencia.' }
    end
    if not exports.cidade_tycoon_core:CheckRateLimit(source, 'emergency_fix_' .. plate, 10000) then
        return { ok = false, message = 'Reparo de emergencia em cooldown.' }
    end
    -- Remove durability from wrench maybe? Or just charge money/items?
    -- For now, it's a basic emergency fix
    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    if not status then return { ok = false, message = 'Veiculo nao registrado.' } end

    if partType == 'engine' then
        status.engine_health = math.min(100.0, status.engine_health + 20.0)
    elseif partType == 'tire' then
        -- Emergency tire fix doesn't add much health, just gets you going
        status.tire_lf_health = math.min(100.0, status.tire_lf_health + 10.0)
        status.tire_rf_health = math.min(100.0, status.tire_rf_health + 10.0)
        status.tire_lr_health = math.min(100.0, status.tire_lr_health + 10.0)
        status.tire_rr_health = math.min(100.0, status.tire_rr_health + 10.0)
    elseif partType and partType:find('tire_') == 1 then
        local column = partType .. '_health'
        if status[column] == nil then return { ok = false, message = 'Pneu invalido.' } end
        status[column] = math.min(100.0, status[column] + 18.0)
    end

    exports.cidade_tycoon_core:UpdateVehicleStatus(plate, status)

    if exports.cidade_tycoon_maintenance.SyncVehicleStateBag then
        exports.cidade_tycoon_maintenance:SyncVehicleStateBag(plate, status)
    end

    return { ok = true, message = 'Reparo de emergencia concluido.' }
end)

local activeWholesale = {}

lib.callback.register('cidade_tycoon_mechanic:server:purchaseWholesale', function(source, itemName, amount)
    local src = source
    if activeWholesale[src] then return { ok = false, message = 'Aguarde...' } end
    activeWholesale[src] = true

    local success, result = pcall(function()
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return { ok = false, message = 'Quantidade invalida.' } end

        local job = exports.cidade_tycoon_core:GetPlayerJob(src)
        if not job or job.name ~= 'mechanic' then
            return { ok = false, message = 'Acesso restrito ao almoxarifado mecanico.' }
        end

        local partData = exports.cidade_tycoon_core:GetPartData(itemName)
        if not partData then return { ok = false, message = 'Peca invalida.' } end

        local discountPrice = math.floor(partData.price * Config.WholesaleDiscount)
        local totalPrice = discountPrice * amount

        if exports.cidade_tycoon_core:RemoveMoney(src, 'bank', totalPrice, 'tycoon-wholesale-purchase') then
            if exports.ox_inventory:AddItem(src, itemName, amount) then
                return { ok = true, message = ('Comprado %d x %s por $%d'):format(amount, partData.label, totalPrice) }
            else
                exports.cidade_tycoon_core:AddMoney(src, 'bank', totalPrice, 'tycoon-wholesale-refund')
                return { ok = false, message = 'Sem espaco na mochila.' }
            end
        end
        return { ok = false, message = ('Saldo insuficiente no banco ($%d).'):format(totalPrice) }
    end)

    activeWholesale[src] = nil
    if success then
        return result
    else
        return { ok = false, message = 'Erro interno ao processar compra: ' .. tostring(result) }
    end
end)

lib.callback.register('cidade_tycoon_mechanic:server:purchaseWholesaleCart', function(source, order)
    local src = source
    if activeWholesale[src] then return { ok = false, message = 'Aguarde...' } end
    activeWholesale[src] = true

    local success, result = pcall(function()
        local job = exports.cidade_tycoon_core:GetPlayerJob(src)
        if not job or job.name ~= 'mechanic' then
            return { ok = false, message = 'Acesso restrito ao almoxarifado mecanico.' }
        end

        if type(order) ~= 'table' then
            return { ok = false, message = 'Carrinho invalido.' }
        end

        local lines = {}
        local totalItems = 0
        local totalPrice = 0

        for _, entry in ipairs(order) do
            local itemName = tostring(entry.name or entry.itemName or '')
            local amount = math.floor(tonumber(entry.amount) or 0)
            if amount <= 0 or amount > 100 then
                return { ok = false, message = 'Quantidade invalida no carrinho.' }
            end

            local partData = exports.cidade_tycoon_core:GetPartData(itemName)
            if not partData then
                return { ok = false, message = ('Peca invalida no carrinho: %s'):format(itemName) }
            end

            local discountPrice = math.floor(partData.price * Config.WholesaleDiscount)
            local subtotal = discountPrice * amount
            lines[#lines + 1] = {
                itemName = itemName,
                amount = amount,
                label = partData.label,
                subtotal = subtotal
            }
            totalItems = totalItems + amount
            totalPrice = totalPrice + subtotal
        end

        if totalItems <= 0 then
            return { ok = false, message = 'Carrinho vazio.' }
        end

        for _, line in ipairs(lines) do
            local canCheck, canCarry = pcall(function()
                return exports.ox_inventory:CanCarryItem(src, line.itemName, line.amount)
            end)
            if canCheck and canCarry == false then
                return { ok = false, message = ('Sem espaco para %s.'):format(line.label) }
            end
        end

        if not exports.cidade_tycoon_core:RemoveMoney(src, 'bank', totalPrice, 'tycoon-wholesale-cart-purchase') then
            return { ok = false, message = ('Saldo insuficiente no banco ($%d).'):format(totalPrice) }
        end

        for _, line in ipairs(lines) do
            if not exports.ox_inventory:AddItem(src, line.itemName, line.amount) then
                exports.cidade_tycoon_core:AddMoney(src, 'bank', totalPrice, 'tycoon-wholesale-cart-refund')
                return { ok = false, message = ('Erro ao entregar %s. Compra reembolsada.'):format(line.label) }
            end
        end

        return { ok = true, message = ('Comprado %d itens por $%d.'):format(totalItems, totalPrice) }
    end)

    activeWholesale[src] = nil
    if success then
        return result
    else
        return { ok = false, message = 'Erro interno ao processar carrinho: ' .. tostring(result) }
    end
end)
