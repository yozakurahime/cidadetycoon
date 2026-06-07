-- ==========================================
-- TYCOON SPEEDRUN TEST SUITE
-- ==========================================

-- 1. TOTAL RESET (Simulate a fresh player)
RegisterCommand('tycoon_reset_flow', function(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return end

    print(("^1[Tycoon:Debug]^7 Iniciando reset total para %s"):format(citizenId))

    -- Clear Memory Cache First
    exports.cidade_tycoon_core:ClearProfileCache(citizenId)

    -- Remove all tycoon related data
    MySQL.update.await('DELETE FROM player_vehicles WHERE citizenid = ?', { citizenId })
    MySQL.update.await('DELETE FROM tycoon_players WHERE citizenid = ?', { citizenId })
    MySQL.update.await('DELETE FROM tycoon_transactions WHERE citizenid = ?', { citizenId })
    MySQL.update.await('DELETE FROM tycoon_financings WHERE citizenid = ?', { citizenId })
    -- Reset inventory (fallback logic)
    MySQL.update.await("UPDATE players SET inventory = '[]', inventorysettings = NULL WHERE citizenid = ?", { citizenId })

    -- Wait for DB sync
    Wait(2000)

    -- Force re-init profile to trigger vehicle grant and initial logic
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    
    -- Grant starting bonus (Wait a bit to avoid framework race conditions)
    Wait(1000)
    player.Functions.AddMoney('bank', 5000, 'tycoon-start-bonus')

    -- Ensure Tablet
    if GetResourceState('cidade_tycoon_tablet') == 'started' then
        exports.cidade_tycoon_tablet:EnsureStarterTabletForSource(source)
    end

    exports.cidade_tycoon_core:NotifyPlayer(source, 'Perfil resetado! Você recebeu $5000, a Faggio e o Tablet.', 'success')
    print(("^2[Tycoon:Debug]^7 Fluxo resetado e recarregado com sucesso para %s"):format(citizenId))
end, true)

-- 2. MANUAL FIX (If everything else fails)
RegisterCommand('tycoon_fix_me', function(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return end

    exports.cidade_tycoon_core:ClearProfileCache(citizenId)
    exports.cidade_tycoon_core:GetPlayerProfile(source)
    
    if GetResourceState('cidade_tycoon_tablet') == 'started' then
        exports.cidade_tycoon_tablet:EnsureStarterTabletForSource(source)
    end
    
    exports.cidade_tycoon_core:NotifyPlayer(source, 'Rotinas de inicialização disparadas manualmente.', 'inform')
end, false)

-- 2.5 FORCE BIKE WITH LOGGING
RegisterCommand('tycoon_force_bike', function(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return end

    local model = 'faggio'
    local plate = "TEST" .. math.random(100, 999)
    local props = json.encode({ plate = plate, engineHealth = 1000.0, bodyHealth = 1000.0, fuelLevel = 100.0, model = model })
    local license = player.PlayerData.license or 'none'

    print(("^3[Tycoon:Debug]^7 Tentando inserir veículo para %s..."):format(citizenId))
    
    local success, err = pcall(function()
        return MySQL.insert.await([[
            INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, type)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], { license, citizenId, model, joaat(model), props, plate, 'public', 1, 'car' })
    end)

    if success and err then
        print(("^2[Tycoon:Debug]^7 Veículo inserido com sucesso! ID: %s"):format(tostring(err)))
        exports.cidade_tycoon_core:NotifyPlayer(source, 'Scooter de teste entregue na garagem global.', 'success')
    else
        local errMsg = tostring(err)
        print(("^1[Tycoon:Debug]^7 FALHA na inserção SQL: %s"):format(errMsg))
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            multiline = true,
            args = { "Tycoon:Debug:Error", "Falha SQL no /tycoon_force_bike: " .. errMsg }
        })
        exports.cidade_tycoon_core:NotifyPlayer(source, 'Falha ao entregar veículo. Veja o chat.', 'error')
    end
end, true)

-- 3. CHECK DATABASE INTEGRITY
RegisterCommand('tycoon_audit_db', function(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return end
    
    local results = {
        profile = MySQL.single.await('SELECT * FROM tycoon_players WHERE citizenid = ?', { citizenId }),
        vehicles = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', { citizenId }),
        inventory_col = MySQL.query.await("SHOW COLUMNS FROM players LIKE 'inventory'")
    }

    print("^3--- AUDITORIA DE BANCO TYCOON ---^7")
    print("CitizenID:", citizenId)
    print("Perfil Existe:", results.profile ~= nil and "^2OK^7" or "^1MISSING^7")
    print("Veículos Registrados:", #results.vehicles)
    print("Coluna Inventário:", #results.inventory_col > 0 and "^2OK^7" or "^1MISSING^7")
    
    if #results.vehicles > 0 then
        for i, v in ipairs(results.vehicles) do
            print(("- [%d] Placa: %s | Modelo: %s | Garagem: %s | Estado: %s"):format(i, v.plate, v.vehicle, v.garage, tostring(v.state)))
        end
    end
    print("^3--------------------------------^7")
    exports.cidade_tycoon_core:NotifyPlayer(source, 'Auditoria concluída. Veja o console.', 'inform')
end, true)

-- 4. GIVE TEST MONEY
RegisterCommand('tycoon_give_funds', function(source, args)
    local amount = tonumber(args[1]) or 50000
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if player then
        player.Functions.AddMoney('bank', amount, 'tycoon-audit-funds')
        exports.cidade_tycoon_core:NotifyPlayer(source, ('Auditoria: +$%d adicionados ao banco.'):format(amount), 'success')
    end
end, true)

RegisterCommand('tycoon_db_diag', function(source)
    if source <= 0 then return end
    
    local success, result = pcall(function()
        return MySQL.query.await("DESCRIBE player_vehicles")
    end)
    
    if success and result then
        exports.cidade_tycoon_core:NotifyPlayer(source, 'Diagnóstico iniciado! Verifique o console F8 do jogo.', 'inform')
        local columns = {}
        for _, col in ipairs(result) do
            table.insert(columns, ("Coluna: '%s' | Tipo: %s | Null: %s | Default: %s"):format(
                tostring(col.Field or col.Column),
                tostring(col.Type),
                tostring(col.Null),
                tostring(col.Default)
            ))
        end
        TriggerClientEvent('cidade_tycoon_core:client:printDiag', source, columns)
    else
        exports.cidade_tycoon_core:NotifyPlayer(source, 'Erro no Diagnóstico: ' .. tostring(result), 'error')
    end
end, false)

RegisterCommand('tycoon_db_vehicles', function(source)
    if source <= 0 then return end
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then
        exports.cidade_tycoon_core:NotifyPlayer(source, 'Erro: citizenId não encontrado!', 'error')
        return
    end

    local success, result = pcall(function()
        return MySQL.query.await("SELECT id, citizenid, vehicle, plate, garage, state, type FROM player_vehicles WHERE citizenid = ?", { citizenId })
    end)
    
    if success and result then
        exports.cidade_tycoon_core:NotifyPlayer(source, 'Veículos do Banco carregados! Verifique o console F8.', 'inform')
        local lines = {}
        table.insert(lines, ("CitizenID Ativo: %s"):format(citizenId))
        table.insert(lines, ("Total de Veículos no Banco: %d"):format(#result))
        for i, col in ipairs(result) do
            table.insert(lines, ("[%d] ID: %s | Modelo: %s | Placa: %s | Garagem: %s | Estado: %s | Tipo: %s"):format(
                i,
                tostring(col.id),
                tostring(col.vehicle),
                tostring(col.plate),
                tostring(col.garage),
                tostring(col.state),
                tostring(col.type)
            ))
        end
        TriggerClientEvent('cidade_tycoon_core:client:printDiag', source, lines)
    else
        exports.cidade_tycoon_core:NotifyPlayer(source, 'Erro ao carregar veículos: ' .. tostring(result), 'error')
    end
end, false)

