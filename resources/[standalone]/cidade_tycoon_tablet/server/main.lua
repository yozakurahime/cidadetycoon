local logisticsConfig = require '@cidade_tycoon_logistics/config/shared'

local WarehousePrices = {
    [1] = 50000,
    [2] = 125000,
    [3] = 225000,
}

local function DebugLog(text, ...)
    print(string.format("^2[Tycoon:Server:Tablet]^7 %s", string.format(text, ...)))
end

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
    print(("[Tycoon:Tablet:Debug] Carregando dashboard para Source: %s, CitizenId: %s"):format(tostring(source), tostring(citizenId)))

    -- 2. Profile Base Data
    payload.name = profile.companyName
    payload.level = profile.level
    payload.experience = profile.experience
    payload.maxExperience = profile.maxExperience
    payload.licenses = profile.licenses

    -- 3. Money Data (Structure expected by frontend: { bank, cash })
    payload.money = { bank = 0, cash = 0 }
    pcall(function()
        payload.money.bank = exports.cidade_tycoon_core:GetMoneyBalance(source, 'bank') or 0
        payload.money.cash = exports.cidade_tycoon_core:GetMoneyBalance(source, 'cash') or 0
    end)
    print(("[Tycoon:Tablet:Debug] Saldo resolvido - Banco: %s, Carteira: %s"):format(tostring(payload.money.bank), tostring(payload.money.cash)))

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
    payload.production = bizData and bizData.activeDeliveries or {}
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
        print(("[Tycoon:Tablet:Debug] Veiculos encontrados no banco de dados para %s: %s"):format(tostring(citizenId), tostring(vehicles and #vehicles or 0)))
        if vehicles then
            for _, veh in ipairs(vehicles) do
                -- Tycoon Matrix Enrichment
                local tycoonData = nil
                local ok, err2 = pcall(function()
                    tycoonData = exports.cidade_tycoon_core:GetVehicleData(veh.vehicle)
                end)
                if not ok then
                    print(("^1[Tycoon:Tablet:Error] Falha ao chamar GetVehicleData para %s: %s^7"):format(tostring(veh.vehicle), tostring(err2)))
                end

                if tycoonData then
                    veh.label = tycoonData.label
                    veh.category = tycoonData.category
                    veh.tier = tycoonData.tier
                    veh.branch = tycoonData.branch
                    veh.capacity = tycoonData.capacity
                    veh.layer = tycoonData.layer
                else
                    print(("[Tycoon:Tablet:Warning] Nao foi possivel obter Matrix Data para o veiculo %s"):format(tostring(veh.vehicle)))
                end

                local status = nil
                local ok3, err3 = pcall(function()
                    status = MySQL.single.await('SELECT * FROM tycoon_vehicle_status WHERE plate = ?', { veh.plate })
                end)
                if not ok3 then
                    print(("^1[Tycoon:Tablet:Error] Falha ao consultar tycoon_vehicle_status para placa %s: %s^7"):format(tostring(veh.plate), tostring(err3)))
                end

                if status then
                    -- Compute overall condition
                    status.overall_condition = math.floor(((status.engine_health or 100) + (status.tires_health or 100)) / 2)
                    veh.maintenance = status
                else
                    veh.maintenance = {
                        overall_condition = 100,
                        odometer_km = 0,
                        engine_health = 100,
                        brakes_health = 100,
                        tires_health = 100,
                        fuel_health = 100
                    }
                end
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
