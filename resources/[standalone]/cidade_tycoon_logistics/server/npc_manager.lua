local sharedConfig = require 'config.shared'

local ActiveNPCDrivers = {} -- [deliveryId] = { pedNetId, vehicleNetId, ownerSource }

local function DebugLog(text, ...)
    print(string.format("^4[Tycoon:Logistics:NPC]^7 %s", string.format(text, ...)))
end

-- NPC Delivery Logic
lib.callback.register('cidade_tycoon_logistics:server:startNPCDelivery', function(source, employeeId, plate, routeType)
    local company = exports.cidade_tycoon_logistics:GetCompanyData(source)
    if not company then return { ok = false, message = 'Empresa nao encontrada.' } end

    -- Verify Employee and Vehicle availability
    local employee = MySQL.single.await('SELECT * FROM tycoon_company_employees WHERE id = ? AND company_id = ? AND status = "available"', { employeeId, company.id })
    if not employee then return { ok = false, message = 'Funcionario indisponivel.' } end

    local vehicle = MySQL.single.await('SELECT * FROM tycoon_company_fleet WHERE vehicle_plate = ? AND company_id = ? AND status = "idle"', { plate, company.id })
    if not vehicle then return { ok = false, message = 'Veiculo indisponivel.' } end

    -- Define Route (Placeholder)
    local routeData = {
        origin = sharedConfig.warehouses[company.warehouseId].coords,
        destination = vec3(100.0, 100.0, 30.0), -- Should be dynamic
        distance = 5000.0,
        type = routeType or 'land'
    }

    -- Insert Delivery Record
    local deliveryId = MySQL.insert.await([[
        INSERT INTO tycoon_npc_deliveries (company_id, employee_id, vehicle_plate, route_data, eta)
        VALUES (?, ?, ?, ?, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 10 MINUTE))
    ]], { company.id, employeeId, plate, json.encode(routeData) })

    if deliveryId then
        -- Set Status to Busy
        MySQL.update.await('UPDATE tycoon_company_employees SET status = "working" WHERE id = ?', { employeeId })
        MySQL.update.await('UPDATE tycoon_company_fleet SET status = "active", assigned_npc_id = ? WHERE vehicle_plate = ?', { employeeId, plate })

        DebugLog("Iniciada entrega NPC #%d para empresa %s", deliveryId, company.name)
        
        -- Trigger client spawn if player is at warehouse
        TriggerClientEvent('cidade_tycoon_logistics:client:spawnNPCDriver', source, {
            deliveryId = deliveryId,
            employeeName = employee.name,
            plate = plate,
            route = routeData
        })

        return { ok = true, message = 'Motorista NPC saiu para entrega!' }
    end

    return { ok = false, message = 'Erro ao iniciar contrato NPC.' }
end)

RegisterNetEvent('cidade_tycoon_logistics:server:reportPhysicalNPC', function(deliveryId, pedNetId, vehicleNetId)
    local src = source
    ActiveNPCDrivers[deliveryId] = {
        pedNetId = pedNetId,
        vehicleNetId = vehicleNetId,
        ownerSource = src
    }
end)

-- Process Virtual Progress (Run every minute)
local function processVirtualNPCDeliveries()
    local deliveries = MySQL.query.await('SELECT * FROM tycoon_npc_deliveries WHERE status = "in_progress"')
    for _, delivery in ipairs(deliveries) do
        -- If no player is nearby (simulated by not being in ActiveNPCDrivers)
        if not ActiveNPCDrivers[delivery.id] then
            local newProgress = (delivery.progress or 0) + 0.1 -- 10% progress per tick
            if newProgress >= 1.0 then
                -- Complete Delivery
                completeNPCDelivery(delivery.id)
            else
                MySQL.update.await('UPDATE tycoon_npc_deliveries SET progress = ? WHERE id = ?', { newProgress, delivery.id })
            end
        end
    end
end

function completeNPCDelivery(deliveryId)
    local delivery = MySQL.single.await('SELECT * FROM tycoon_npc_deliveries WHERE id = ?', { deliveryId })
    if not delivery or delivery.status ~= 'in_progress' then return end

    local reward = 2500 -- Base profit for NPC work
    
    -- Update Company Funds
    exports.cidade_tycoon_logistics:AddCompanyFunds(delivery.company_id, reward, 'Entrega NPC concluída')

    -- Cleanup
    MySQL.update.await('UPDATE tycoon_npc_deliveries SET status = "completed", progress = 1.0 WHERE id = ?', { deliveryId })
    MySQL.update.await('UPDATE tycoon_company_employees SET status = "available" WHERE id = ?', { delivery.employee_id })
    MySQL.update.await('UPDATE tycoon_company_fleet SET status = "idle", assigned_npc_id = NULL WHERE vehicle_plate = ?', { delivery.vehicle_plate })

    DebugLog("Entrega NPC #%d concluída. Lucro: $%d", deliveryId, reward)
end

-- Task management logic
CreateThread(function()
    while true do
        Wait(60000) -- Every 1 minute
        processVirtualNPCDeliveries()
    end
end)
