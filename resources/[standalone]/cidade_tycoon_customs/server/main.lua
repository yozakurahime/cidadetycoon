local sharedConfig = require 'config.shared'

local function DebugLog(text, ...)
    print(string.format("^5[Tycoon:Server:Customs]^7 %s", string.format(text, ...)))
end

-- Persist properties to database
local function saveVehicleProperties(plate, props)
    if not plate or not props then return false end

    local success = MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', {
        json.encode(props),
        plate
    })

    if success > 0 then
        DebugLog("Propriedades do veiculo %s salvas com sucesso.", plate)
        return true
    end
    return false
end

exports('SaveVehicleProperties', saveVehicleProperties)

-- Purchase and Persist Mod
lib.callback.register('cidade_tycoon_customs:server:purchaseMod', function(source, plate, modType, price, currentProps)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if not player then return { ok = false, message = 'Erro ao identificar jogador.' } end

    -- Validation
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < price then
        return { ok = false, message = ('Saldo insuficiente ($%d).'):format(price) }
    end

    -- Process payment
    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', price, 'tycoon-vehicle-customization') then
        -- Save properties sent by client
        if saveVehicleProperties(plate, currentProps) then
            exports.cidade_tycoon_core:LogTransaction(source, price, 'expense', 'customization', 'Customização estética: ' .. (modType or 'visual'))
            return { ok = true, message = 'Customização aplicada e salva com sucesso!' }
        else
            -- Refund if DB fails
            player.Functions.AddMoney('bank', price, 'tycoon-customs-refund')
            return { ok = false, message = 'Erro ao salvar alteração no banco de dados.' }
        end
    end

    return { ok = false, message = 'Falha ao processar pagamento.' }
end)

