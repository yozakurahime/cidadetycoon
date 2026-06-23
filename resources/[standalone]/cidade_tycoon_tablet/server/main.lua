local success, logisticsConfig = pcall(require, '@cidade_tycoon_logistics/config/shared')
if not success then logisticsConfig = {} end

local WarehousePrices = {
    [1] = 50000,
    [2] = 125000,
    [3] = 225000,
}

local isDebug = false
local function DebugLog(text, ...)
    if isDebug then
        print(string.format("^2[Tycoon:Server:Tablet]^7 %s", string.format(text, ...)))
    end
end

local function normalizePlate(plate)
    return exports.cidade_tycoon_core:NormalizePlate(plate)
end

local function buildMaintenanceStatus(status, vehicleModel)
    status = type(status) == 'table' and status or {}
    local isElectric = exports.cidade_tycoon_core:IsVehicleElectric(vehicleModel)
    local tireHealth = math.min(
        status.tire_lf_health or status.tires_health or 100,
        status.tire_rf_health or status.tires_health or 100,
        status.tire_lr_health or status.tires_health or 100,
        status.tire_rr_health or status.tires_health or 100
    )

    local engineCondition = isElectric and (status.battery_health or 100) or (status.engine_health or 100)
    local transmissionCondition = isElectric and 100 or (status.transmission_health or 100)
    local overall = math.floor(math.min(
        engineCondition,
        transmissionCondition,
        status.brakes_health or 100,
        status.suspension_health or 100,
        tireHealth,
        status.body_health or 100
    ))

    local subsystems = {}
    if isElectric then
        subsystems[#subsystems + 1] = { subsystem = 'battery', label = 'Bateria', condition = status.battery_health or 100 }
    else
        subsystems[#subsystems + 1] = { subsystem = 'engine', label = 'Motor', condition = status.engine_health or 100 }
        subsystems[#subsystems + 1] = { subsystem = 'transmission', label = 'Transmissao', condition = status.transmission_health or 100 }
    end
    subsystems[#subsystems + 1] = { subsystem = 'brakes', label = 'Freios', condition = status.brakes_health or 100 }
    subsystems[#subsystems + 1] = { subsystem = 'suspension', label = 'Suspensao', condition = status.suspension_health or 100 }
    subsystems[#subsystems + 1] = { subsystem = 'tires', label = 'Pneus', condition = tireHealth }
    subsystems[#subsystems + 1] = { subsystem = 'body', label = 'Lataria', condition = status.body_health or 100 }

    local mileage = tonumber(status.mileage) or 0
    local recommendation = 'Revisao em dia'
    if overall <= 40 then
        recommendation = 'Manutencao urgente recomendada'
    elseif overall <= 70 then
        recommendation = 'Agendar revisao preventiva'
    end

    return {
        overall_condition = overall,
        condition = overall,
        odometer_km = mileage,
        mileage = mileage,
        last_service_odometer_km = tonumber(status.last_service_odometer_km) or 0,
        next_service_due_km = mileage + 2500,
        next_service_recommendation = recommendation,
        outstanding_balance = tonumber(status.outstanding_balance) or 0,
        body_health = status.body_health or 100,
        battery_charge = isElectric and (status.battery_charge or 100) or nil,
        subsystems = subsystems,
    }
end

-- Load debug flag from core config
local function initDebug()
    local ok, cfg = pcall(exports.cidade_tycoon_core.GetCoreConfig)
    if ok and cfg then
        isDebug = cfg.isDebug or false
    end
end
initDebug()
local function getWarehouseList()
    local warehouses = {}
    for id, warehouse in pairs(logisticsConfig.warehouses or {}) do
        warehouses[#warehouses + 1] = {
            id = id,
            name = warehouse.name,
            price = warehouse.price or WarehousePrices[id] or 75000,
            coords = warehouse.coords,
        }
    end
    table.sort(warehouses, function(a, b) return a.id < b.id end)
    return warehouses
end

local function decodeCoords(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) ~= 'string' or raw == '' then return nil end
    local ok, decoded = pcall(json.decode, raw)
    if ok then return decoded end
    return nil
end

-- ==========================================
-- OPTIMIZED AGGREGATED DASHBOARD (Arbiter Design)
-- ==========================================

local function getDashboardForSource(source)
    local profile = nil
    pcall(function()
        profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    end)
    if not profile then return nil end

    local citizenId = profile.citizenid

    -- Tutorial Auto-Advance Checks (Wrapped in pcall to prevent coordinates/OneSync runtime crashes)
    pcall(function()
        if profile.tutorial and profile.tutorial.active then
            if profile.tutorial.currentStep == 'welcome' then
                profile.tutorial.currentStep = 'go_to_garage'
                exports.cidade_tycoon_core:UpdateTutorialStep(source, 'go_to_garage')
            elseif profile.tutorial.currentStep == 'go_to_hub' then
                local ped = GetPlayerPed(source)
                if ped and ped > 0 then
                    local coords = GetEntityCoords(ped)
                    if coords and coords ~= vector3(0.0, 0.0, 0.0) then
                        local dist = #(coords - vector3(1197.2, -3250.6, 7.1))
                        if dist < 50.0 then
                            profile.tutorial.currentStep = 'accept_tutorial_contract'
                            exports.cidade_tycoon_core:UpdateTutorialStep(source, 'accept_tutorial_contract')
                        end
                    end
                end
            end
        end
    end)

    local payload = {}

    -- Debug: log de dados do perfil inicial
    DebugLog("Carregando dashboard para Source: %s, CitizenId: %s", tostring(source), tostring(citizenId))

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)

    -- 2. Profile Base Data
    payload.name = profile.companyName
    payload.level = profile.level
    payload.experience = profile.experience
    payload.maxExperience = profile.maxExperience
    payload.licenses = profile.licenses
    payload.job = player and player.PlayerData.job.name or 'unemployed'

    -- 3. Money Data (Structure expected by frontend: { bank, cash })
    payload.money = { bank = 0, cash = 0 }
    pcall(function()
        payload.money.bank = exports.cidade_tycoon_core:GetMoneyBalance(source, 'bank') or 0
        payload.money.cash = exports.cidade_tycoon_core:GetMoneyBalance(source, 'cash') or 0
    end)
    DebugLog("Saldo resolvido - Banco: %s, Carteira: %s", tostring(payload.money.bank), tostring(payload.money.cash))

    -- 4. Fetch Business Data (Logistics)
    local bizData = nil
    if GetResourceState('cidade_tycoon_logistics') == 'started' then
        local success, result = pcall(function()
            return exports.cidade_tycoon_logistics:GetBusinessDashboardForSource(source)
        end)
        if success then
            bizData = result
        end
    end
    payload.company = bizData and {
        hasCompany = bizData.hasCompany,
        id = bizData.company and bizData.company.id,
        name = bizData.company and bizData.company.name,
        level = bizData.company and bizData.company.level,
        vault = bizData.company and (bizData.company.vault_balance or bizData.company.vaultBalance),
        employeesCount = # (bizData.employees or {}),
        activeRoutes = # (bizData.activeDeliveries or {})
    } or { hasCompany = false }
    payload.hasCompany = bizData and bizData.hasCompany or false
    payload.warehouses = getWarehouseList()
    payload.warehouseStock = {}
    if payload.hasCompany and payload.company.id then
        pcall(function()
            payload.warehouseStock = MySQL.query.await('SELECT item_key, amount FROM tycoon_warehouse_inventory WHERE company_id = ? AND amount > 0', { payload.company.id }) or {}
        end)
    end
    payload.staff = bizData and bizData.employees or {}
    payload.routes = bizData and bizData.activeDeliveries or {}
    payload.fleet = {}
    if bizData and bizData.company and bizData.company.id then
        pcall(function()
            payload.fleet = MySQL.query.await('SELECT * FROM tycoon_company_fleet WHERE company_id = ?', { bizData.company.id }) or {}
        end)
    end

    -- 5. Fetch Garage Fleet (vehicles property inside garage)
    payload.garage = { vehicles = {} }
    local success, err = pcall(function()
        local vehicles = MySQL.query.await('SELECT id, vehicle, plate, garage, state FROM player_vehicles WHERE citizenid = ?', { citizenId })
        if vehicles then
            -- Batch fetch ALL vehicle statuses in a single query
            local plates = {}
            for _, veh in ipairs(vehicles) do
                plates[#plates + 1] = veh.plate
            end

            local statusMap = {}
            if #plates > 0 then
                local placeholders = {}
                local params = {}
                for i, plate in ipairs(plates) do
                    placeholders[#placeholders + 1] = '?'
                    params[#params + 1] = normalizePlate(plate)
                end
                local statusRows = MySQL.query.await(([[SELECT * FROM tycoon_vehicle_status WHERE REPLACE(UPPER(plate), ' ', '') IN (%s)]]):format(table.concat(placeholders, ',')), params)
                if statusRows then
                    for _, row in ipairs(statusRows) do
                        statusMap[normalizePlate(row.plate)] = row
                    end
                end
            end

            for _, veh in ipairs(vehicles) do
                -- Tycoon Matrix Enrichment
                local tycoonData = nil
                pcall(function()
                    tycoonData = exports.cidade_tycoon_core:GetVehicleData(veh.vehicle)
                end)

                if tycoonData then
                    veh.label = tycoonData.label
                    veh.category = tycoonData.category
                    veh.tier = tycoonData.tier
                    veh.branch = tycoonData.branch
                    veh.capacity = tycoonData.capacity
                    veh.layer = tycoonData.layer
                end

                -- Lookup status from batch map instead of individual query
                local status = statusMap[normalizePlate(veh.plate)]
                veh.maintenance = buildMaintenanceStatus(status, veh.vehicle)
            end
            payload.garage.vehicles = vehicles
        end
    end)
    if not success then
        print(("^1[Tycoon:Tablet:Error] Falha geral no bloco de carregamento de veiculos: %s^7"):format(tostring(err)))
    end

    -- 6. Hubs
    payload.hubs = exports.cidade_tycoon_hubs:GetAllHubs()

    -- 7. Get Freelance Mission Context
    local freelanceCtx = { hasActiveMission = false, activeMission = nil }
    if GetResourceState('cidade_tycoon_freelance') == 'started' then
        local success, result = pcall(function()
            return exports.cidade_tycoon_freelance:GetCompanyAndFreelanceContextForSource(source)
        end)
        if success and result then
            freelanceCtx = result
        end
    end
    payload.hasActiveMission = freelanceCtx.hasActiveMission
    payload.activeMission = freelanceCtx.activeMission

    -- 8. Tutorial
    payload.tutorial = profile.tutorial and {
        currentStep = profile.tutorial.currentStep,
        active = profile.tutorial.active,
        assignedGarage = 'Garagem Tycoon Inicial',
        assignedHubName = 'PostOP Hub (LS)'
    } or { active = false }

    -- 9. Available Jobs (Job board passthrough)
    payload.availableJobs = {}
    pcall(function()
        payload.availableJobs = MySQL.query.await('SELECT j.*, c.company_name FROM tycoon_job_board j JOIN tycoon_companies c ON j.company_id = c.id ORDER BY j.created_at DESC LIMIT 10') or {}
    end)

    return payload
end

lib.callback.register('cidade_tycoon_tablet:server:getDashboard', getDashboardForSource)

lib.callback.register('cidade_tycoon_tablet:server:advanceTutorialStep', function(source, stepName, payload)
    local success = exports.cidade_tycoon_core:UpdateTutorialStep(source, stepName, payload)
    return { ok = success }
end)

lib.callback.register('cidade_tycoon_tablet:server:purchaseCompany', function(source, warehouseId)
    -- Rate limit + input validation
    if not exports.cidade_tycoon_core:CheckRateLimit(source, 'purchase_company', 5000) then
        return { ok = false, message = 'Aguarde antes de tentar novamente.' }
    end
    warehouseId = tonumber(warehouseId)
    local warehouse = warehouseId and logisticsConfig.warehouses and logisticsConfig.warehouses[warehouseId]
    if not warehouse then return { ok = false, message = 'Galpao invalido.' } end

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return { ok = false, message = 'Perfil nao carregado.' } end

    local existing = MySQL.single.await('SELECT id FROM tycoon_companies WHERE citizenid = ?', { citizenId })
    if existing then return { ok = false, message = 'Voce ja possui uma empresa logistica.' } end

    local price = warehouse.price or WarehousePrices[warehouseId] or 75000
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < price then
        return { ok = false, message = ('Saldo insuficiente. Necessario: $%s'):format(price) }
    end

    if not exports.cidade_tycoon_core:RemoveMoney(player, 'bank', price, 'tablet-company-purchase') then
        return { ok = false, message = 'Falha ao processar pagamento.' }
    end

    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    local companyName = (profile and profile.companyName) or 'Nova Empresa Logistica'
    MySQL.insert.await([[
        INSERT INTO tycoon_companies (citizenid, name, warehouse_id, vault_balance)
        VALUES (?, ?, ?, 0)
    ]], { citizenId, companyName, warehouseId })

    -- Clear profile cache and reload to instantly update State Bags on client
    pcall(function()
        exports.cidade_tycoon_core:ClearProfileCache(citizenId)
        exports.cidade_tycoon_core:GetPlayerProfile(source)
    end)

    pcall(function()
        exports.cidade_tycoon_core:LogTransaction(source, price, 'expense', 'company', ('Compra de galpao: %s'):format(warehouse.name))
    end)

    return { ok = true, message = ('Empresa criada em %s.'):format(warehouse.name) }
end)

lib.callback.register('cidade_tycoon_tablet:server:acceptJobBoardJob', function(source, jobId)
    jobId = tonumber(jobId)
    if not jobId then return { ok = false, message = 'Contrato invalido.' } end

    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile or not profile.citizenid then return { ok = false, message = 'Perfil nao carregado.' } end

    local job = MySQL.single.await('SELECT * FROM tycoon_job_board WHERE id = ?', { jobId })
    if not job or job.status ~= 'posted' then
        return { ok = false, message = 'Contrato indisponivel.' }
    end

    local changed = MySQL.update.await([[
        UPDATE tycoon_job_board
        SET status = 'taken', assigned_citizenid = ?
        WHERE id = ? AND status = 'posted'
    ]], { profile.citizenid, jobId })

    if not changed or changed < 1 then
        return { ok = false, message = 'Outro motorista pegou esse contrato primeiro.' }
    end

    return { ok = true, message = 'Contrato aceito com sucesso!' }
end)

-- ==========================================
-- EXPORTS
-- ==========================================

exports('GetDashboardForSource', getDashboardForSource)

exports('EnsureStarterTabletForSource', function(source)
    return exports.cidade_tycoon_core:EnsureStarterItem(source, 'tablet', 1)
end)

-- ==========================================
-- ITEM REGISTRATION (Modern Qbox/Ox)
-- ==========================================

local function registerTabletItem()
    exports.cidade_tycoon_core:CreateUseableItem('tablet', function(source)
        TriggerClientEvent('cidade_tycoon_tablet:client:openTablet', source)
    end)
    DebugLog("Item 'tablet' registrado como utilizável.")
end

AddEventHandler('onResourceStart', function(res)
    if res == 'ox_inventory' or res == GetCurrentResourceName() then
        Wait(1500)
        registerTabletItem()
    end
end)

-- Command for admins/debug
RegisterCommand('tablet', function(source)
    if source <= 0 then return end
    TriggerClientEvent('cidade_tycoon_tablet:client:openTablet', source)
end, true)

RegisterCommand('tablet_payload', function(source)
    if source <= 0 then return end
    local dashboard = getDashboardForSource(source)
    if dashboard then
        print("^2[Tycoon:Tablet:Debug] --- INICIO PAYLOAD DO TABLET ---^7")
        print("Nome:", dashboard.name)
        print("Level:", dashboard.level)
        print("Exp:", dashboard.experience)
        print("Total de Veiculos na Frota:", (dashboard.garage and dashboard.garage.vehicles and #dashboard.garage.vehicles or 0))
        if dashboard.garage and dashboard.garage.vehicles then
            for i, v in ipairs(dashboard.garage.vehicles) do
                print(("- [%d] Placa: %s | Modelo: %s | Garagem: %s | Estado: %s | Label: %s"):format(
                    i, tostring(v.plate), tostring(v.vehicle), tostring(v.garage), tostring(v.state), tostring(v.label)
                ))
            end
        end
        print("^2[Tycoon:Tablet:Debug] --- FIM PAYLOAD DO TABLET ---^7")
        exports.cidade_tycoon_core:NotifyPlayer(source, 'Payload dumpado no console do servidor.', 'inform')
    else
        print("^1[Tycoon:Tablet:Debug] Perfil do jogador nao encontrado ou nulo.^7")
    end
end, true)

AddEventHandler('qbx_core:server:onPlayerLoaded', function(source)
    -- Ensure player has the tool
    exports.cidade_tycoon_core:EnsureStarterItem(source, 'tablet', 1)
end)

-- ==========================================
-- CUSTOMS PENDING ORDERS CALLBACKS
-- ==========================================


lib.callback.register('cidade_tycoon_tablet:server:payOperationalDebt', function(source, vehicleId)
    return { ok = false, message = 'Nenhum debito operacional pendente para este veiculo.' }
end)
lib.callback.register('cidade_tycoon_tablet:server:getCustomsOrders', function(source)
    local src = source
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    if not player then return { clientOrders = {}, mechanicOrders = {}, isMechanic = false } end
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    local isMechanic = player.PlayerData.job.name == 'mechanic'

    local clientOrders = MySQL.query.await([[
        SELECT * FROM tycoon_customs_orders
        WHERE client_citizenid = ? AND status = 'pending'
        ORDER BY created_at DESC
    ]], { citizenId }) or {}

    local mechanicOrders = {}
    if isMechanic then
        mechanicOrders = MySQL.query.await([[
            SELECT * FROM tycoon_customs_orders
            WHERE mechanic_citizenid = ? AND status = 'pending'
            ORDER BY created_at DESC
        ]], { citizenId }) or {}
    end

    return {
        clientOrders = clientOrders,
        mechanicOrders = mechanicOrders,
        isMechanic = isMechanic
    }
end)

lib.callback.register('cidade_tycoon_tablet:server:payCustomsOrder', function(source, orderId)
    if not exports.cidade_tycoon_core:CheckRateLimit(source, 'pay_customs', 3000) then
        return { ok = false, message = 'Aguarde antes de realizar outra operacao.' }
    end
    orderId = tonumber(orderId)
    if not orderId or orderId <= 0 then
        return { ok = false, message = 'Ordem de servico invalida.' }
    end
    local src = source
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    if not player then return { ok = false, message = 'Jogador inválido.' } end
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)

    local order = MySQL.single.await('SELECT * FROM tycoon_customs_orders WHERE id = ? AND client_citizenid = ? AND status = \'pending\'', { orderId, citizenId })
    if not order then return { ok = false, message = 'Ordem de serviço não encontrada ou já paga.' } end

    -- Check balance
    local bankBalance = exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank')
    if bankBalance < order.total then
        return { ok = false, message = 'Saldo bancário insuficiente.' }
    end

    -- Remove money
    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', order.total, 'tycoon-customs-order-payment') then
        local modsTable = json.decode(order.mods)

        -- Save mods to vehicle (player_vehicles table)
        local saveSuccess = false
        pcall(function()
            local normalizedPlate = tostring(order.plate):gsub('^%s*(.-)%s*$', '%1')
            local affected = MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ? OR TRIM(plate) = ?', { order.mods, order.plate, normalizedPlate })
            saveSuccess = (affected and affected > 0)
        end)

        if saveSuccess then
            -- Update order status
            MySQL.update.await('UPDATE tycoon_customs_orders SET status = \'paid\' WHERE id = ?', { orderId })

            -- Route Payment: Mechanic Labor Fee and Parts Subtotal
            local feeVal = tonumber(order.fee) or 0
            local subtotalVal = tonumber(order.subtotal) or 0

            -- 1. Labor fee to Mechanic (handles online and offline states)
            if feeVal > 0 then
                local mechanicCitizenId = order.mechanic_citizenid
                local mechanicPlayer = exports.cidade_tycoon_core:GetPlayerFromCitizenId(mechanicCitizenId)

                if mechanicPlayer then
                    -- Mechanic is online: AddMoney directly
                    exports.cidade_tycoon_core:AddMoney(mechanicPlayer, 'bank', feeVal, 'tycoon-mechanic-labor-fee')
                    local mechanicSource = mechanicPlayer.PlayerData.source
                    TriggerClientEvent('ox_lib:notify', mechanicSource, {
                        title = 'Ordem de Serviço Paga',
                        description = ('Você recebeu R$%d pela OS pendente do veículo %s.'):format(feeVal, order.plate),
                        type = 'success'
                    })
                else
                    -- Mechanic is offline: Safe transactional database update of player's JSON bank money
                    pcall(function()
                        local result = MySQL.single.await('SELECT money FROM players WHERE citizenid = ?', { mechanicCitizenId })
                        if result and result.money then
                            local moneyTable = json.decode(result.money)
                            if moneyTable and moneyTable.bank then
                                moneyTable.bank = moneyTable.bank + feeVal
                                MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(moneyTable), mechanicCitizenId })
                            end
                        end
                    end)
                end
            end

            -- 2. Parts cost (subtotal) goes to society_mechanic fund
            if subtotalVal > 0 then
                exports.okokBanking:AddSocietyMoney('society_mechanic', subtotalVal)
            end

            -- Log transaction
            exports.cidade_tycoon_core:LogTransaction(src, order.total, 'expense', 'customization', ('Pagamento OS Pendente: %s'):format(order.plate))

            -- Broadcast work order published event
            local itemsList = json.decode(order.items) or {}
            local clientName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
            TriggerEvent('cidade_tycoon_customs:server:createWorkOrder', {
                plate = order.plate,
                client = clientName,
                mechanic = order.mechanic_name,
                total = order.total,
                items = itemsList
            })

            -- Sync modifications to the spawned vehicle if active
            TriggerClientEvent('cidade_tycoon_customs:client:applyPaidMods', -1, order.plate, modsTable)

            return { ok = true, message = 'Ordem de serviço paga com sucesso! Modificações aplicadas ao veículo.' }
        else
            -- Refund on database fail
            exports.cidade_tycoon_core:AddMoney(player, 'bank', order.total, 'tycoon-customs-order-refund')
            return { ok = false, message = 'Erro ao salvar modificações no banco de dados. Reembolsado.' }
        end
    end

    return { ok = false, message = 'Falha no processamento financeiro.' }
end)

lib.callback.register('cidade_tycoon_tablet:server:cancelCustomsOrder', function(source, orderId)
    local src = source
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(src)
    if not player or player.PlayerData.job.name ~= 'mechanic' then
        return { ok = false, message = 'Apenas mecânicos podem cancelar ordens de serviço.' }
    end
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)

    local changed = MySQL.update.await([[
        UPDATE tycoon_customs_orders
        SET status = 'cancelled'
        WHERE id = ? AND mechanic_citizenid = ? AND status = 'pending'
    ]], { orderId, citizenId })

    if changed and changed > 0 then
        return { ok = true, message = 'Ordem de serviço cancelada com sucesso.' }
    end
    return { ok = false, message = 'Ordem de serviço não encontrada ou já processada.' }
end)
