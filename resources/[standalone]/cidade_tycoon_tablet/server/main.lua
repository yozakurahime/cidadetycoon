local CORE = 'cidade_tycoon_core'
local FREELANCE = 'cidade_tycoon_freelance'
local MAINTENANCE = 'cidade_tycoon_maintenance'

local function getFrameworkPlayer(source)
    return exports.cidade_tycoon_core:GetFrameworkPlayer(source)
end

local function getCitizenId(player)
    return exports.cidade_tycoon_core:GetCitizenId(player)
end

local function notifyPlayer(source, message, notificationType)
    if GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:Notify(source, message, notificationType or 'inform')
        return
    end
    TriggerClientEvent('QBCore:Notify', source, message, notificationType or 'primary')
end

-- Ensure player has a physical tablet
local function ensureStarterTablet(source)
    if GetResourceState('ox_inventory') == 'started' then
        local itemCount = exports.ox_inventory:Search(source, 'count', 'tablet') or 0
        if itemCount == 0 then
            exports.ox_inventory:AddItem(source, 'tablet', 1)
        end
        return true
    end
    -- Fallback for qb-inventory or similar could go here
    return true
end

-- AGGREGATED DASHBOARD (The Core of the Tablet)
local function getDashboardForSource(source)
    print(("^5[Tycoon:Tablet]^7 Gerando dashboard para jogador %d..."):format(source))
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then 
        print("^1[Tycoon:Tablet]^7 Falha ao obter perfil do jogador.")
        return nil 
    end

    local player = getFrameworkPlayer(source)
    
    -- 1. Profile Data (Core)
    local payload = {
        citizenid = profile.citizenid,
        companyName = profile.companyName,
        level = profile.level,
        experience = profile.experience,
        maxExperience = profile.maxExperience or (profile.level * 2000),
        reputation = profile.reputation or 0,
        reputationProduction = profile.reputationProduction or 0,
        reputationFiscal = profile.reputationFiscal or 0,
        hybridScore = profile.hybridScore or 0,
        licenses = profile.licenses,
        tutorial = profile.tutorial,
        money = {
            bank = player and player.Functions.GetMoney('bank') or 0,
            cash = player and player.Functions.GetMoney('cash') or 0,
        }
    }

    print(("^5[Tycoon:Tablet]^7 Dinheiro recuperado: Banco $%d, Mao $%d"):format(payload.money.bank, payload.money.cash))

    -- 2. Maintenance / Upgrades (Maintenance Module)
    if GetResourceState(MAINTENANCE) == 'started' then
        pcall(function()
            local maintenanceData = exports.cidade_tycoon_maintenance:GetUpgradeDashboardForSource(source)
            if maintenanceData then
                payload.upgrades = maintenanceData.upgrades
                payload.effects = maintenanceData.effects
            end
        end)
    end

    -- 3. Active Mission Status (Freelance Module)
    if GetResourceState(FREELANCE) == 'started' then
        pcall(function()
            local freelanceContext = exports.cidade_tycoon_freelance:GetCompanyAndFreelanceContextForSource(source)
            if freelanceContext and freelanceContext.hasActiveMission then
                local m = freelanceContext.activeMission
                payload.hasActiveMission = true
                payload.activeMission = {
                    missionId = m.missionId,
                    mode = m.mode,
                    contractType = m.contractType,
                    vehicleModel = m.vehicleModel,
                    totalRequired = m.totalRequired,
                    totalDelivered = m.totalDelivered,
                    inTrunk = m.inTrunk,
                    capacity = m.capacity,
                    cargoHealth = m.cargoHealth,
                    reward = freelanceContext.estimatedReward or 0
                }
            end
        end)
    end

    -- 4. Financings (Market Module)
    if GetResourceState('cidade_tycoon_market') == 'started' then
        pcall(function()
            payload.financings = exports.cidade_tycoon_market:GetPlayerFinancings(source)
        end)
    end

    -- 5. Transaction History
    pcall(function()
        payload.history = exports.cidade_tycoon_core:GetPlayerTransactions(source, 15)
    end)

    -- 6. Business Data (Logistics & Production)
    if GetResourceState('cidade_tycoon_logistics') == 'started' then
        pcall(function()
            local bizData = exports.cidade_tycoon_logistics:GetBusinessDashboardForSource(source)
            if bizData then
                payload.hasCompany = bizData.hasCompany
                payload.company = bizData.company
                payload.employees = bizData.employees
                payload.fleet = bizData.fleet
                payload.activeDeliveries = bizData.activeDeliveries
                payload.productionLines = bizData.productionLines
                payload.warehouses = bizData.warehouses
            end
        end)
    end

    -- 7. Available Jobs (Job Board)
    if GetResourceState('cidade_tycoon_logistics') == 'started' then
        pcall(function()
            payload.availableJobs = exports.cidade_tycoon_logistics:GetAvailableJobsForSource(source)
        end)
    end

    -- 6. Hubs Data
    if GetResourceState('cidade_tycoon_hubs') == 'started' then
        pcall(function()
            payload.hubs = exports.cidade_tycoon_hubs:GetAllHubs()
        end)
    end

    -- 7. Fleet Health & Alerts
    payload.alerts = {}
    pcall(function()
        local fleetStatus = MySQL.query.await([[
            SELECT s.*, v.vehicle 
            FROM tycoon_vehicle_status s
            JOIN player_vehicles v ON s.plate = v.plate
            WHERE v.citizenid = ?
        ]], { profile.citizenid })

        if fleetStatus then
            for _, veh in ipairs(fleetStatus) do
                local criticalParts = {}
                if veh.engine_health < 25 then table.insert(criticalParts, 'Motor') end
                if veh.tires_health < 25 then table.insert(criticalParts, 'Pneus') end
                if veh.brakes_health < 25 then table.insert(criticalParts, 'Freios') end

                if #criticalParts > 0 then
                    table.insert(payload.alerts, {
                        type = 'warning',
                        title = ('Alerta de Manutenção: %s'):format(veh.vehicle:upper()),
                        message = ('Componentes críticos (%s). Siga para uma oficina.'):format(table.concat(criticalParts, ', '))
                    })
                end
            end
        end
    end)

    -- 8. Vehicle Data with Maintenance Integration
    payload.garage = { vehicles = {} }
    pcall(function()
        local vehicles = MySQL.query.await('SELECT id, vehicle, plate, garage, state FROM player_vehicles WHERE citizenid = ?', { profile.citizenid })
        if vehicles then
            for _, veh in ipairs(vehicles) do
                -- Tycoon Matrix Enrichment
                local tycoonData = exports.cidade_tycoon_core:GetVehicleData(veh.vehicle)
                if tycoonData then
                    veh.label = tycoonData.label
                    veh.category = tycoonData.category
                    veh.tier = tycoonData.tier
                    veh.branch = tycoonData.branch
                    veh.capacity = tycoonData.capacity
                    veh.layer = tycoonData.layer
                end

                local status = MySQL.single.await('SELECT * FROM tycoon_vehicle_status WHERE plate = ?', { veh.plate })
                if status then
                    veh.maintenance = status
                else
                    -- Default maintenance state if not found
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
            print(("^5[Tycoon:Tablet]^7 %d veiculos recuperados para a frota."):format(#vehicles))
        end
    end)

    return payload
end

lib.callback.register('cidade_tycoon_tablet:server:getDashboard', getDashboardForSource)
exports('GetDashboardForSource', getDashboardForSource)

-- Waypoint Management
RegisterNetEvent('cidade_tycoon_tablet:server:setWaypoint', function(coords)
    local src = source
    TriggerClientEvent('cidade_tycoon_tablet:client:setWaypoint', src, coords)
end)

-- Passthrough for Tutorial and Freelance Actions
lib.callback.register('cidade_tycoon_tablet:server:advanceTutorialStep', function(source, nextStepKey, options)
    return exports.cidade_tycoon_freelance:AdvanceTutorialStepForSource(source, nextStepKey, options or {})
end)

lib.callback.register('cidade_tycoon_tablet:server:tablet_accept_job', function(source, jobId)
    local profile = exports.cidade_tycoon_core:GetPlayerProfile(source)
    if not profile then return { ok = false, message = 'Perfil nao encontrado.' } end
    
    -- In standard job mural flow, hubId is the owner's hub
    local job = MySQL.single.await('SELECT warehouse_id FROM tycoon_companies c JOIN tycoon_job_board j ON j.company_id = c.id WHERE j.id = ?', { jobId })
    if not job then return { ok = false, message = 'Contrato nao encontrado.' } end

    return exports.cidade_tycoon_freelance:StartPlayerBulkContractForSource(source, job.warehouse_id, jobId)
end)

lib.callback.register('cidade_tycoon_tablet:server:cancelFreelanceWithFine', function(source)
    return exports.cidade_tycoon_freelance:CancelFreelanceWithFineForSource(source)
end)

-- Item and Command Logic
RegisterNetEvent('qbx_core:server:onPlayerLoaded', function(source)
    ensureStarterTablet(source)
end)

if GetResourceState('qbx_core') == 'started' then
    exports.qbx_core:CreateUseableItem('tablet', function(source)
        TriggerClientEvent('cidade_tycoon_tablet:client:openTablet', source)
    end)
end

RegisterCommand('tablet', function(source)
    if source <= 0 then return end
    ensureStarterTablet(source)
    TriggerClientEvent('cidade_tycoon_tablet:client:openTablet', source)
end, false)

exports('EnsureStarterTabletForSource', ensureStarterTablet)
