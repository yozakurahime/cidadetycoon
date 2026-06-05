local function DebugLog(text, ...)
    print(string.format("^4[Tycoon:Server:Maintenance]^7 %s", string.format(text, ...)))
end

local function getActiveMechanicsCount()
    local count = 0
    local players = exports.qbx_core:GetPlayers()
    for _, src in ipairs(players) do
        local player = exports.qbx_core:GetPlayer(src)
        if player and (player.PlayerData.job.name == 'mechanic' or player.PlayerData.job.name == 'bennys') and player.PlayerData.job.onduty then
            count = count + 1
        end
    end
    return count
end

-- Callbacks
lib.callback.register('cidade_tycoon_maintenance:server:getWorkshopVehicleData', function(source, workshopKey, plate)
    local vehicle = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicle then return { ok = false, message = 'Veiculo nao registrado no sistema.' } end

    local status = exports.cidade_tycoon_core:GetVehicleStatus(plate)
    local profile = {
        overallCondition = (status.engine_health + status.transmission_health + status.brakes_health + status.suspension_health + status.tires_health) / 5.0,
        odometerKm = status.mileage,
        subsystems = {
            engine = { label = 'Motor', condition = status.engine_health },
            transmission = { label = 'Transmissão', condition = status.transmission_health },
            brakes = { label = 'Freios', condition = status.brakes_health },
            suspension = { label = 'Suspensão', condition = status.suspension_health },
            tires = { label = 'Pneus', condition = status.tires_health },
        }
    }

    local mechanicsOnline = getActiveMechanicsCount()
    
    local availableParts = {}
    local playerItems = exports.ox_inventory:Items(source)
    
    if playerItems then
        for _, item in pairs(playerItems) do
            local partData = exports.cidade_tycoon_core:GetPartData(item.name)
            if partData then
                table.insert(availableParts, {
                    name = item.name,
                    label = partData.label,
                    category = partData.category,
                    count = item.count,
                    repairValue = partData.repairValue
                })
            end
        end
    end
    
    return {
        ok = true,
        vehicle = {
            plate = plate,
            modelName = vehicle.vehicle,
        },
        profile = profile,
        mechanicsOnline = mechanicsOnline,
        useNPCMechanic = mechanicsOnline == 0,
        availableParts = availableParts
    }
end)

-- Profile helpers using Core Exports and State Bags
local function getProfile(source)
    local stateProfile = Player(source).state.tycoonProfile
    if stateProfile then return stateProfile end
    return exports.cidade_tycoon_core:GetPlayerProfile(source)
end

-- Upgrade Logic
local function getUpgradeDashboardForSource(source)
    local profile = getProfile(source)
    if not profile then return nil end

    -- Use the exported version if available, otherwise just mock or something. Wait, TycoonCore?
    -- No, use exports.cidade_tycoon_core
    local effects = exports.cidade_tycoon_core:FormatUpgradeEffects(profile.upgrades)
    local dashboard = {
        companyName = profile.companyName,
        level = profile.level,
        experience = profile.experience,
        upgrades = {},
        effects = effects,
    }

    local definitions = exports.cidade_tycoon_core:GetUpgradesDefinition()
    for upgradeKey, definition in pairs(definitions or {}) do
        local currentLevel = profile.upgrades[upgradeKey] or 0
        local upgradeCost = exports.cidade_tycoon_core:CalculateUpgradeCost(upgradeKey, currentLevel)

        dashboard.upgrades[upgradeKey] = {
            key = upgradeKey,
            displayName = definition.displayName,
            level = currentLevel,
            maxLevel = definition.maxLevel,
            nextCost = upgradeCost,
            isMaxed = currentLevel >= definition.maxLevel,
        }
    end

    return dashboard
end

lib.callback.register('cidade_tycoon_maintenance:server:getUpgradeDashboard', getUpgradeDashboardForSource)
exports('GetUpgradeDashboardForSource', getUpgradeDashboardForSource)


lib.callback.register('cidade_tycoon_maintenance:server:purchaseUpgrade', function(source, upgradeKey)
    local profile = getProfile(source)
    if not profile then return { ok = false, message = 'Perfil nao encontrado.' } end

    local definitions = exports.cidade_tycoon_core:GetUpgradesDefinition()
    local definition = definitions and definitions[upgradeKey]
    if not definition then return { ok = false, message = 'Upgrade invalido.' } end

    local currentLevel = profile.upgrades[upgradeKey] or 0
    if currentLevel >= definition.maxLevel then
        return { ok = false, message = 'Nivel maximo atingido.' }
    end

    local cost = exports.cidade_tycoon_core:CalculateUpgradeCost(upgradeKey, currentLevel)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < cost then
        return { ok = false, message = ('Saldo insuficiente. Custo: $%d'):format(cost) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', cost, 'tycoon-upgrade-purchase') then
        profile.upgrades[upgradeKey] = currentLevel + 1
        exports.cidade_tycoon_core:UpdateUpgrades(source, profile.upgrades)
        
        DebugLog("Jogador %s comprou upgrade %s para o nivel %d", profile.citizenid, upgradeKey, profile.upgrades[upgradeKey])
        
        return { 
            ok = true, 
            message = ('Upgrade %s adquirido com sucesso!'):format(definition.displayName),
            newLevel = profile.upgrades[upgradeKey]
        }
    end

    return { ok = false, message = 'Falha ao processar pagamento.' }
end)

lib.callback.register('cidade_tycoon_maintenance:server:payOperationalDebt', function(source, vehicleId)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    
    -- Fetch outstanding balance from player_vehicles or maintenance table
    -- Placeholder: simple payment
    return { ok = true, message = 'Debito quitado.' }
end)

lib.callback.register('cidade_tycoon_maintenance:server:repairSubsystem', function(source, plate, itemName)
    local partData = exports.cidade_tycoon_core:GetPartData(itemName)
    if not partData then return { ok = false, message = 'Peça invalida.' } end

    local mechanicsOnline = getActiveMechanicsCount()
    local laborFee = 0
    if mechanicsOnline == 0 then
        laborFee = 1500 -- Taxa fixa de mão de obra NPC
    end

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if laborFee > 0 and exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < laborFee then
        return { ok = false, message = ('Saldo insuficiente para a mão de obra NPC ($%d).'):format(laborFee) }
    end

    -- Verify inventory
    local itemCount = exports.ox_inventory:Search(source, 'count', itemName) or 0
    if itemCount < 1 then
        return { ok = false, message = 'Voce nao possui esta peça no inventario.' }
    end

    if exports.ox_inventory:RemoveItem(source, itemName, 1) then
        if laborFee > 0 then
            exports.cidade_tycoon_core:RemoveMoney(player, 'bank', laborFee, 'tycoon-npc-labor-fee')
            exports.cidade_tycoon_core:LogTransaction(source, laborFee, 'expense', 'repair', 'Mão de obra NPC: ' .. partData.label)
        end

        local success = exports.cidade_tycoon_core:ApplyPartRepair(plate, partData.category, partData.repairValue)
        
        if success then
            -- Generate Scrap
            local scrapItem = 'mechanical_scrap'
            if partData.category == 'engine' or partData.category == 'transmission' then
                scrapItem = 'mechanical_scrap'
            elseif itemName == 'basic_repair_kit' then
                scrapItem = 'electronic_scrap'
            elseif partData.category == 'tires' then
                scrapItem = 'rubber_scrap'
            end
            
            if exports.ox_inventory:CanCarryItem(source, scrapItem, 1) then
                exports.ox_inventory:AddItem(source, scrapItem, 1)
            end

            local msg = ('Reparo de %s concluído! Você recuperou sucata.'):format(partData.label)
            if laborFee > 0 then msg = msg .. (' (Taxa NPC: $%d)'):format(laborFee) end
            return { ok = true, message = msg }
        end
    end

    return { ok = false, message = 'Erro ao realizar reparo.' }
end)

lib.callback.register('cidade_tycoon_maintenance:server:purchaseAndRepairNPC', function(source, plate, itemName)
    local mechanicsOnline = getActiveMechanicsCount()
    if mechanicsOnline > 0 then
        return { ok = false, message = 'Existem mecanicos na cidade. Procure um profissional.' }
    end

    local partData = exports.cidade_tycoon_core:GetPartData(itemName)
    if not partData then return { ok = false, message = 'Peça invalida.' } end

    local totalCost = partData.price + 2500 -- Preço da peça + Mão de obra "Premium" NPC
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)

    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < totalCost then
        return { ok = false, message = ('Saldo insuficiente ($%d necessário).'):format(totalCost) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', totalCost, 'tycoon-npc-full-service') then
        local success = exports.cidade_tycoon_core:ApplyPartRepair(plate, partData.category, partData.repairValue)
        if success then
            exports.cidade_tycoon_core:LogTransaction(source, totalCost, 'expense', 'repair', 'Serviço Completo NPC: ' .. partData.label)
            return { ok = true, message = ('Serviço completo de %s realizado pelo NPC!'):format(partData.label) }
        end
    end

    return { ok = false, message = 'Falha no serviço NPC.' }
end)

