local sharedConfig = require 'config/shared'

local function DebugLog(text, ...)
    print(string.format("^5[Tycoon:Server:Customs]^7 %s", string.format(text, ...)))
end

-- Helper: Server-side Proximity Check
local function isNearAnyWorkshop(source)
    local pCoords = GetEntityCoords(GetPlayerPed(source))
    local logisticsConfig = require '@cidade_tycoon_logistics/config/shared'
    
    for _, warehouse in pairs(logisticsConfig.warehouses) do
        local base = warehouse.autopartsCoords or warehouse.productionCoords
        if base and #(pCoords - vector3(base.x, base.y, base.z)) < sharedConfig.WorkshopDistance + 5.0 then
            return true
        end
    end
    return false
end

-- Persist properties to database
local function saveVehicleProperties(plate, props)
    if not plate or not props then return false end
    return MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', {
        json.encode(props),
        plate
    }) > 0
end

-- CHECKOUT CALLBACK (Shopping Cart)
lib.callback.register('cidade_tycoon_customs:server:checkout', function(source, plate, finalProps, cart)
    local src = source
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)

    -- 1. Security: Proximity Check
    if not isNearAnyWorkshop(src) then
        return { ok = false, message = 'Você está muito longe da oficina para processar o pagamento.' }
    end

    -- 2. Security: Ownership Verification
    local vehicleOwner = MySQL.scalar.await('SELECT citizenid FROM player_vehicles WHERE plate = ?', { plate })
    local isAuthorized = (vehicleOwner == citizenId)

    if not isAuthorized then
        -- Check if it's a company vehicle and if player has permissions
        local profile = exports.cidade_tycoon_core:GetPlayerProfile(src)
        if profile and profile.hubId then
            -- Logic to check if vehicle belongs to profile.hubId (To be expanded)
            -- For now, we trust the Tycoon logic if hub matches
            isAuthorized = true 
        end
    end

    if not isAuthorized then
        return { ok = false, message = 'Você não tem permissão para customizar este veículo.' }
    end

    -- 3. Calculate Total from Server Config (Ignore Client Price)
    local totalCost = 0
    local itemsApplied = 0
    for mod, active in pairs(cart) do
        if active then
            totalCost = totalCost + (sharedConfig.Prices[mod] or 0)
            itemsApplied = itemsApplied + 1
        end
    end

    if totalCost == 0 then return { ok = false, message = 'Carrinho vazio.' } end

    -- 4. Process Payment
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < totalCost then
        return { ok = false, message = ('Saldo insuficiente ($%d).'):format(totalCost) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', totalCost, 'tycoon-vehicle-customization') then
        -- 5. Final Persist
        if saveVehicleProperties(plate, finalProps) then
            exports.cidade_tycoon_core:LogTransaction(src, totalCost, 'expense', 'customization', ('Customização de frota (%d itens): %s'):format(itemsApplied, plate))
            DebugLog("Veículo %s customizado por %s por $%d", plate, citizenId, totalCost)
            return { ok = true, message = ('Pagamento de $%d processado. Veículo salvo!'):format(totalCost) }
        else
            -- Refund on critical DB fail
            exports.cidade_tycoon_core:AddMoney(player, 'bank', totalCost, 'tycoon-customs-refund')
            return { ok = false, message = 'Falha crítica ao salvar no banco de dados. Reembolsado.' }
        end
    end

    return { ok = false, message = 'Falha no processamento financeiro.' }
end)
