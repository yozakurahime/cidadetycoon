local RESOURCE = GetCurrentResourceName()
local isOpen = {}
local eventLocks = {}
local activeJobs = {}

local function corePlayer(source)
    return exports.cidade_tycoon_core:GetFrameworkPlayer(source)
end

local function citizenId(source)
    local p = corePlayer(source)
    return p and p.PlayerData.citizenid
end

local function playerSourceByCitizenId(citizenId)
    local players = exports.qbx_core:GetQBPlayers()
    for _, player in pairs(players) do
        if player.PlayerData.citizenid == citizenId then
            return player.PlayerData.source
        end
    end
    return nil
end

local function number(val)
    return tonumber(val) or 0
end

local function integer(val, min, max)
    local n = tonumber(val)
    if not n then return nil end
    n = math.floor(n)
    if min and n < min then n = min end
    if max and n > max then n = max end
    return n
end

local function clone(t)
    if type(t) ~= 'table' then return t end
    local res = {}
    for k, v in pairs(t) do res[k] = clone(v) end
    return res
end

local function notify(source, message, notifyType)
    TriggerClientEvent('qbx_core:client:notify', source, message, notifyType == 'primary' and 'inform' or (notifyType or 'inform'))
end

local function withLock(source, fn)
    if eventLocks[source] then return end
    eventLocks[source] = true
    fn()
    eventLocks[source] = nil
end

local function companyDebit(userId, amount)
    local row = MySQL.single.await('SELECT money FROM trucker_users WHERE user_id = ?', { userId })
    if not row or number(row.money) < amount then return false end
    MySQL.update.await('UPDATE trucker_users SET money = money - ? WHERE user_id = ?', { amount, userId })
    return true
end

local function companyCredit(userId, amount)
    MySQL.update.await('UPDATE trucker_users SET money = money + ?, total_earned = total_earned + ? WHERE user_id = ?', { amount, amount, userId })
end

local function ensureUser(userId)
    local user = MySQL.single.await('SELECT * FROM trucker_users WHERE user_id = ?', { userId })
    if not user then
        MySQL.insert.await('INSERT INTO trucker_users (user_id) VALUES (?)', { userId })
        user = MySQL.single.await('SELECT * FROM trucker_users WHERE user_id = ?', { userId })
    end
    return user
end

local function refreshOpenPlayers()
    for source, _ in pairs(isOpen) do
        openUI(source, true)
    end
end

local function contractDistance(contract, empresaId)
    local emp = Config.empresas[empresaId or 'trucker_1']
    if not emp then return nil end
    local start = vector3(emp.coordenada[1], emp.coordenada[2], emp.coordenada[3])
    local destCoords = Config.locais_entrega[contract.coords_index]
    local dest = vector3(destCoords[1], destCoords[2], destCoords[3])
    return tonumber(string.format("%.2f", #(start - dest) / 1000))
end

function formatCurrency(amount, config)
    return "$" .. amount 
end

function openUI(source, update)
    local userId = citizenId(source)
    if not userId then return end
    local user = ensureUser(userId)
    
    local payload = {
        trucker_users = user,
        trucker_available_contracts = MySQL.query.await('SELECT * FROM trucker_available_contracts', {}),
        trucker_trucks = MySQL.query.await('SELECT * FROM trucker_trucks WHERE user_id = ?', { userId }),
        trucker_drivers = MySQL.query.await('SELECT * FROM trucker_drivers WHERE user_id = ? OR user_id IS NULL', { userId }),
        trucker_loans = MySQL.query.await('SELECT * FROM trucker_loans WHERE user_id = ?', { userId }),
        server_time = os.time(),
        config = {
            concessionaria = clone(Config.concessionaria),
            formatacao = clone(Config.formatacao),
            valor_reparo = clone(Config.valor_reparo),
            exp_por_level = clone(Config.exp_por_level),
            habilidade_distancia = clone(Config.habilidade_distancia),
            emprestimos = clone(Config.emprestimos.valores),
            multiplicador_venda = Config.multiplicador_venda,
            trabalhos = clone(Config.trabalhos),
            motoristas = clone(Config.motoristas)
        }
    }
    TriggerClientEvent('cidade_tycoon_trucklogistics:open', source, payload, update)
end

function generateContract()
    local name = "Contrato de Logística #" .. math.random(1000, 9999)
    local coordsIndex = math.random(#Config.locais_entrega)
    local pricePerKm = math.random(Config.contratos.preco_por_km_min, Config.contratos.preco_por_km_max)
    local cargo = Config.contratos.cargas[math.random(#Config.contratos.cargas)]
    local isUrgente = math.random(100) <= Config.contratos.probabilidade_ser_carga_urgente and 1 or 0
    local type = math.random(100) <= 30 and 1 or 0 
    local truck = Config.contratos.caminhoes[math.random(#Config.contratos.caminhoes)]

    MySQL.insert.await([[INSERT INTO trucker_available_contracts 
        (contract_type, contract_name, coords_index, price_per_km, cargo_type, fragile, valuable, fast, truck, trailer) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        type, cargo.nome, coordsIndex, pricePerKm, cargo.def[1], cargo.def[2], cargo.def[3], isUrgente, truck, cargo.carga
    })
end

function generateDriver()
    local set = Config.motoristas.nomes[math.random(#Config.motoristas.nomes)]
    local name = set.nomes[math.random(#set.nomes)]
    local price = math.random(Config.motoristas.preco_min, Config.motoristas.preco_max)
    local priceKm = math.random(Config.motoristas.preco_por_km_min, Config.motoristas.preco_por_km_max)
    
    MySQL.insert.await([[INSERT INTO trucker_drivers 
        (name, product_type, distance, valuable, fragile, fast, price, price_per_km, img) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        name, math.random(0, 3), math.random(0, 3), math.random(0, 1), math.random(0, 1), math.random(0, 1), price, priceKm, set.img
    })
end

-- MAIN DRIVER SIMULATION THREAD
CreateThread(function()
    Wait(10000)
    while true do
        local drivers = MySQL.query.await([[SELECT d.*, t.truck_id
            FROM trucker_trucks t INNER JOIN trucker_drivers d ON t.driver = d.driver_id
            WHERE t.driver IS NOT NULL AND t.driver <> 0]], {})
        
        local now = os.time()
        for _, driver in ipairs(drivers) do
            local source = playerSourceByCitizenId(driver.user_id)
            if Config.trabalhos.gera_dinheiro_offline or source then
                if driver.status ~= 'WAITING_DECISION' then
                    if driver.timer == 0 or now >= driver.timer then
                        local currentStatus = driver.status or 'IDLE'
                        local nextStatus = 'PREPARING'
                        local nextWait = 2 * 60 
                        local currentJobReward = driver.current_job_reward or 0
                        local currentCargoName = driver.current_cargo_name
                        local routeEvents = driver.route_events and json.decode(driver.route_events) or {}
                        local activeEvent = nil
                        local penaltyCost = 0
                        local pendingEventData = nil
                        local workedTime = 0

                        -- Se o motorista não estava descansando, acumula o tempo do estágio anterior
                        if currentStatus ~= 'IDLE' and driver.timer > 0 then
                            workedTime = math.max(0, now - (driver.timer - 120)) -- estimativa baseada no cooldown ou tempo decorrido
                            -- Na verdade, o mais preciso é saber quando ele começou.
                            -- Mas como o timer é o fim, o tempo trabalhado é o tempo total do estágio que acabou de passar.
                        end

                        if currentStatus == 'IDLE' then
                            nextStatus = 'PREPARING'
                            nextWait = 2 * 60
                            local randomCargo = Config.contratos.cargas[math.random(#Config.contratos.cargas)]
                            currentCargoName = randomCargo.nome
                            routeEvents = {}
                        elseif currentStatus == 'PREPARING' then
                            nextStatus = 'LOADING'
                            nextWait = 3 * 60
                        elseif currentStatus == 'LOADING' then
                            nextStatus = 'TRANSIT'
                            local skillTotal = number(driver.product_type) + number(driver.distance) + number(driver.fragile) + number(driver.valuable) + number(driver.fast)
                            local amount = math.random(Config.trabalhos.valor_inicial_min, Config.trabalhos.valor_inicial_max)
                            currentJobReward = math.floor(amount * (1 + skillTotal * Config.trabalhos.porcentagem_bonus_habilidades / 100))
                            
                            local baseTime = math.random(15, 25)
                            local cargoModifier = 0
                            local cargoData = nil
                            for _, c in ipairs(Config.contratos.cargas) do
                                if c.nome == currentCargoName then cargoData = c; break end
                            end
                            if cargoData then
                                if cargoData.def[1] > 0 then cargoModifier = cargoModifier + 3 table.insert(routeEvents, { name = "Protocolo ADR", time = 3 }) end
                                if cargoData.def[2] == 1 then cargoModifier = cargoModifier + 5 table.insert(routeEvents, { name = "Carga Frágil", time = 5 }) end
                                if cargoData.def[3] == 1 then cargoModifier = cargoModifier + 2 table.insert(routeEvents, { name = "Carga Valiosa", time = 2 }) end
                            end
                            
                            local baseRisk = 50
                            local actualRisk = math.max(10, baseRisk - (number(driver.level) * 2))
                            
                            if math.random(100) <= actualRisk then
                                local eventRoll = math.random(0, 100)
                                local damageData = { engine = 0, transmission = 0, body = 0, wheels = 0 }
                                if eventRoll > 85 then -- PRF (Interactive)
                                    nextStatus, activeEvent = 'WAITING_DECISION', "Bloqueio PRF"
                                    pendingEventData = json.encode({ type = 'PRF' })
                                    table.insert(routeEvents, { name = "Retido PRF", time = 12 })
                                    if source then 
                                        notify(source, ("🚔 PRF: %s parado! Instruções pendentes no Tablet."):format(driver.name), 'error') 
                                        TriggerClientEvent('cidade_tycoon_tablet:client:showToast', source, '🚨 EMERGÊNCIA LOGÍSTICA', ('O motorista %s foi parado pela PRF e aguarda ordens.'):format(driver.name), 10000)
                                    end
                                elseif eventRoll > 70 then -- Breakdown (Interactive)
                                    nextStatus, activeEvent = 'WAITING_DECISION', "Falha Mecânica"
                                    pendingEventData = json.encode({ type = 'BREAKDOWN' })
                                    table.insert(routeEvents, { name = "Pane Mecânica", time = 15 })
                                    if source then 
                                        notify(source, ("⚠️ ALERTA: Quebra com %s! Instruções pendentes no Tablet."):format(driver.name), 'error') 
                                        TriggerClientEvent('cidade_tycoon_tablet:client:showToast', source, '🛠️ FALHA MECÂNICA', ('O veículo de %s quebrou. Decida o tipo de reparo no Tablet.'):format(driver.name), 10000)
                                    end
                                elseif eventRoll > 55 then -- Robbery (Interactive)
                                    nextStatus, activeEvent = 'WAITING_DECISION', "Tentativa de Assalto"
                                    pendingEventData = json.encode({ type = 'ROBBERY' })
                                    table.insert(routeEvents, { name = "Abordagem Armada", time = 20 })
                                    if source then 
                                        notify(source, ("🚨 ALERTA: Assalto em andamento com %s! Instruções no Tablet."):format(driver.name), 'error') 
                                        TriggerClientEvent('cidade_tycoon_tablet:client:showToast', source, '🚨 ROUBO EM ANDAMENTO', ('O motorista %s foi abordado por assaltantes armados!'):format(driver.name), 10000)
                                    end
                                elseif eventRoll > 40 then -- Accident
                                    activeEvent = "Colisão Leve"
                                    cargoModifier, penaltyCost = cargoModifier + 15, math.random(3000, 7000)
                                    damageData.body, damageData.engine = 350, 60
                                    table.insert(routeEvents, { name = "Acidente", time = 15 })
                                elseif eventRoll > 25 then -- Tire
                                    activeEvent = "Pneu Furado"
                                    cargoModifier, penaltyCost = cargoModifier + 6, 800
                                    damageData.wheels = 250
                                    table.insert(routeEvents, { name = "Troca Pneu", time = 6 })
                                elseif eventRoll > 10 then -- Storm
                                    activeEvent = "Tempestade"
                                    cargoModifier = cargoModifier + 10
                                    damageData.wheels = 50
                                    table.insert(routeEvents, { name = "Tempo Severo", time = 10 })
                                elseif eventRoll < 5 then -- Strategic Shortcut
                                    activeEvent = "Atalho Estratégico"
                                    cargoModifier = cargoModifier - 7
                                    table.insert(routeEvents, { name = "Atalho", time = -7 })
                                end
                                if nextStatus ~= 'WAITING_DECISION' and (damageData.engine > 0 or damageData.body > 0 or damageData.wheels > 0) then
                                    MySQL.update.await([[UPDATE trucker_trucks SET engine = IF(engine > ?, engine - ?, 0), transmission = IF(transmission > ?, transmission - ?, 0), body = IF(body > ?, body - ?, 0), wheels = IF(wheels > ?, wheels - ?, 0) WHERE truck_id = ?]], { damageData.engine, damageData.engine, damageData.transmission, damageData.transmission, damageData.body, damageData.body, damageData.wheels, damageData.wheels, driver.truck_id })
                                end
                            end
                            if penaltyCost > 0 then
                                companyDebit(driver.user_id, penaltyCost)
                                MySQL.update.await([[UPDATE trucker_drivers SET total_spent = total_spent + ? WHERE driver_id = ?]], { penaltyCost, driver.driver_id })
                            end
                            nextWait = (baseTime + cargoModifier) * 60
                        elseif currentStatus == 'TRANSIT' then
                            nextStatus = 'RETURNING'
                            nextWait = math.random(5, 10) * 60
                        elseif currentStatus == 'RETURNING' then
                            nextStatus = 'IDLE'
                            nextWait = 10 * 60
                            local routeKm = math.random(15, 45)
                            if companyDebit(driver.user_id, number(driver.price_per_km)) then
                                companyCredit(driver.user_id, currentJobReward)
                                local netProfit = currentJobReward - number(driver.price_per_km)
                                if source then
                                    notify(source, ("📦 %s concluiu a entrega! Lucro: %s"):format(driver.name, formatCurrency(netProfit, Config)), 'success')
                                    TriggerClientEvent('cidade_tycoon_tablet:client:showToast', source, '📦 ENTREGA CONCLUÍDA', ('O motorista %s finalizou a rota. Lucro Líquido: %s'):format(driver.name, formatCurrency(netProfit, Config)), 7000)
                                end
                                MySQL.update.await([[UPDATE trucker_drivers SET 
                                    total_profit = total_profit + ?, 
                                    total_spent = total_spent + ?,
                                    finished_deliveries = finished_deliveries + 1,
                                    traveled_distance = traveled_distance + ?
                                    WHERE driver_id = ?]], { currentJobReward, number(driver.price_per_km), routeKm, driver.driver_id })
                                local wear = math.random(20, 50)
                                MySQL.update.await([[UPDATE trucker_trucks SET engine = IF(engine > ?, engine - ?, 0), transmission = IF(transmission > ?, transmission - ?, 0), body = IF(body > ?, body - ?, 0), wheels = IF(wheels > ?, wheels - ?, 0) WHERE truck_id = ?]], { wear, wear, wear, wear, math.floor(wear/2), math.floor(wear/2), wear * 2, wear * 2, driver.truck_id })
                            else
                                nextStatus, nextWait = 'IDLE', 60 * 60
                                if source then notify(source, Lang[Config.lang].driver_failed:format(driver.name), 'error') end
                            end
                            currentJobReward, currentCargoName, activeEvent = 0, nil, nil
                            routeEvents = {}
                        end
                        MySQL.update.await([[UPDATE trucker_drivers SET status = ?, timer = ?, current_job_reward = ?, current_cargo_name = ?, active_event = ?, pending_event_data = ?, route_events = ?, total_work_time = total_work_time + ? WHERE driver_id = ?]], { nextStatus, now + nextWait, currentJobReward, currentCargoName, activeEvent, pendingEventData, json.encode(routeEvents), workedTime, driver.driver_id })
                        if source and isOpen[source] then openUI(source, true) end
                    end
                end
            end
            Wait(50)
        end
        Wait(60000)
    end
end)

CreateThread(function()
    Wait(5000)
    local dc = number(MySQL.scalar.await('SELECT COUNT(*) FROM trucker_drivers WHERE user_id IS NULL'))
    if dc < 6 then for i=1,6-dc do generateDriver() end refreshOpenPlayers() end
    local cc = number(MySQL.scalar.await('SELECT COUNT(*) FROM trucker_available_contracts'))
    if cc < 12 then for i=1,12-cc do generateContract() end refreshOpenPlayers() end
end)

CreateThread(function()
    Wait(15000)
    while true do
        generateContract()
        refreshOpenPlayers()
        Wait(Config.contratos.cooldown * 60000)
    end
end)

CreateThread(function()
    Wait(20000)
    while true do
        generateDriver()
        refreshOpenPlayers()
        Wait(Config.motoristas.cooldown * 60000)
    end
end)

CreateThread(function()
    Wait(10000)
    while true do
        local loans = MySQL.query.await('SELECT * FROM trucker_loans', {})
        for _, loan in ipairs(loans) do
            if number(loan.timer) + Config.emprestimos.cooldown < os.time() then
                local source = playerSourceByCitizenId(loan.user_id)
                if companyDebit(loan.user_id, loan.day_cost) then
                    local remaining = number(loan.remaining_amount) - number(loan.taxes_on_day)
                    if remaining > 0 then
                        MySQL.update.await('UPDATE trucker_loans SET remaining_amount = ?, timer = ? WHERE id = ?', { remaining, os.time(), loan.id })
                    else
                        MySQL.update.await('DELETE FROM trucker_loans WHERE id = ?', { loan.id })
                    end
                elseif source then
                    notify(source, Lang[Config.lang].no_loan_money, 'inform')
                else
                    MySQL.update.await('UPDATE trucker_users SET loan_notify = 1 WHERE user_id = ?', { loan.user_id })
                end
                if source and isOpen[source] then openUI(source, true) end
            end
        end
        Wait(600000)
    end
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:getData', function()
    local source = source
    if not citizenId(source) then return end
    isOpen[source] = true
    openUI(source, false)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:closeUI', function()
    isOpen[source] = nil
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:startContract', function(data)
    local source = source
    withLock(source, function()
        local userId = citizenId(source)
        local contractId = type(data) == 'table' and integer(data.id, 1) or nil
        if not userId or not contractId or activeJobs[source] then return end
        local contract = MySQL.single.await('SELECT * FROM trucker_available_contracts WHERE contract_id = ?', { contractId })
        if not contract then return notify(source, Lang[Config.lang].job_already_started, 'error') end
        local user = ensureUser(userId)
        local distance = contractDistance(contract, type(data) == 'table' and tostring(data.empresa) or nil)
        if not distance then return end
        if number(user.product_type) < number(contract.cargo_type) then return notify(source, Lang[Config.lang].no_skill_5, 'error') end
        if number(user.fragile) < number(contract.fragile) then return notify(source, Lang[Config.lang].no_skill_4, 'error') end
        if number(user.valuable) < number(contract.valuable) then return notify(source, Lang[Config.lang].no_skill_3, 'error') end
        if number(user.fast) < number(contract.fast) then return notify(source, Lang[Config.lang].no_skill_2, 'error') end
        if number(Config.habilidade_distancia[number(user.distance)]) < distance then return notify(source, Lang[Config.lang].no_skill_1, 'error') end
        local isRental = number(contract.contract_type) == 0
        local truck = {}
        if not isRental then
            truck = MySQL.single.await('SELECT * FROM trucker_trucks WHERE user_id = ? AND (driver IS NULL OR driver = 0) LIMIT 1', { userId })
            if not truck then return notify(source, Lang[Config.lang].own_truck, 'error') end
        end
        if MySQL.update.await('DELETE FROM trucker_available_contracts WHERE contract_id = ?', { contractId }) == 0 then
            return notify(source, Lang[Config.lang].job_already_started, 'error')
        end
        local reward = math.floor(distance * number(contract.price_per_km))
        activeJobs[source] = { userId = userId, contract = contract, distance = distance, reward = reward, truck = truck, startedAt = os.time() }
        TriggerClientEvent('cidade_tycoon_trucklogistics:startContract', source, contract, distance, reward, truck)
        refreshOpenPlayers()
    end)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:trainDriver', function(driverId)
    local source = source
    local userId = citizenId(source)
    driverId = integer(driverId, 1)
    if not userId or not driverId then return end
    local driver = MySQL.single.await('SELECT * FROM trucker_drivers WHERE driver_id = ? AND user_id = ?', { driverId, userId })
    if not driver then return end
    if (driver.level or 1) >= 20 then return notify(source, "Nível máximo!", "error") end
    local trainCost = math.floor(Config.motoristas.preco_min * 0.5 * (1.3 ^ (driver.level or 1)))
    if companyDebit(userId, trainCost) then
        MySQL.update.await('UPDATE trucker_drivers SET level = level + 1, total_spent = total_spent + ? WHERE driver_id = ?', { trainCost, driverId })
        TriggerClientEvent('cidade_tycoon_trucklogistics:successSound', source)
        notify(source, ("Treinamento concluído! %s agora é Nível %d."):format(driver.name, (driver.level or 1) + 1), "success")
        openUI(source, true)
    else notify(source, "Saldo insuficiente!", "error") end
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:resolveCrisis', function(data)
    local source = source
    local userId = citizenId(source)
    local driverId = type(data) == 'table' and integer(data.driver_id, 1) or nil
    local option = type(data) == 'table' and tostring(data.option) or nil
    if not userId or not driverId or not option then return end
    local driver = MySQL.single.await('SELECT * FROM trucker_drivers WHERE driver_id = ? AND user_id = ?', { driverId, userId })
    if not driver or driver.status ~= 'WAITING_DECISION' then return end
    local eventData = json.decode(driver.pending_event_data)
    local penaltyCost, damageData, nextWait, resultMessage = 0, {engine=0,transmission=0,body=0,wheels=0}, 5*60, ""
    
    if eventData.type == 'PRF' then
        if option == 'cooperate' then
            resultMessage = "🚨 PRF: O motorista cooperou. Multa de R$3.500 paga pela empresa. Atraso de 10 min na rota."
            penaltyCost = 3500
            nextWait = 10*60
        elseif option == 'bribe' then
            if math.random(100) > 40 then
                resultMessage = "🤫 PRF: Suborno de R$7.000 aceito! O motorista foi liberado com apenas 1 min de atraso."
                penaltyCost = 7000
                nextWait = 1*60
            else
                resultMessage = "👮 PRF: O suborno falhou! Multa de R$21.000 aplicada e o motorista ficou retido por 30 min!"
                penaltyCost = 21000
                nextWait = 30*60
            end
        elseif option == 'flee' then
            if math.random(100) > 70 then
                resultMessage = "💨 PRF: O motorista deu fuga com sucesso! Sem multas, mas as rodas foram destruídas (100% de desgaste)."
                damageData.wheels = 1000
            else
                resultMessage = "🚨 PRF: A fuga falhou! O motorista foi capturado, chassi sofreu danos graves (50% de desgaste) e uma multa de R$15.000 foi aplicada, com 45 min de atraso!"
                penaltyCost = 15000
                damageData.body = 500
                nextWait = 45*60
            end
        end
    elseif eventData.type == 'BREAKDOWN' then
        if option == 'official' then
            resultMessage = "🛠️ MECÂNICA: Reparo oficial concluído por R$9.000. Transmissão 100% reparada, atraso de 15 min."
            penaltyCost = 9000
            MySQL.update.await('UPDATE trucker_trucks SET transmission = 1000 WHERE truck_id = ?', { driver.truck_id })
            nextWait = 15*60
        elseif option == 'cheap' then
            resultMessage = "🔧 MECÂNICA: Gambiarra concluída por R$2.000. O motor sofreu 35% de desgaste, mas o atraso foi de apenas 8 min."
            penaltyCost = 2000
            damageData.engine = 350
            nextWait = 8*60
        end
    elseif eventData.type == 'ROBBERY' then
        if option == 'surrender' then
            resultMessage = "🚨 ASSALTO: Carga entregue. Ninguém se feriu, mas houve perda total da recompensa e multa contratual de R$5.000."
            penaltyCost = 5000
            nextWait = 10 * 60
            MySQL.update.await('UPDATE trucker_drivers SET current_job_reward = 0 WHERE driver_id = ?', { driverId })
        elseif option == 'reag' then
            if math.random(100) > 50 then
                resultMessage = "💪 REAGIU: O motorista acelerou por cima e escapou dos assaltantes com sucesso! Carga e caminhão intactos!"
                nextWait = 2 * 60
            else
                resultMessage = "💥 REAGIU: Fuga falhou! Caminhão foi alvejado, sofreu danos graves no motor/chassi (60% de desgaste), 50% da carga foi perdida e multa médica de R$8.000 cobrada."
                penaltyCost = 8000
                damageData.engine = 600
                damageData.body = 600
                nextWait = 40 * 60
                MySQL.update.await('UPDATE trucker_drivers SET current_job_reward = current_job_reward * 0.5 WHERE driver_id = ?', { driverId })
            end
        elseif option == 'police' then
            if math.random(100) > 40 then
                resultMessage = "🚔 POLÍCIA: Polícia interceptou a quadrilha! Assaltantes fugiram e a carga foi salva com 15 min de atraso."
                nextWait = 15 * 60
            else
                resultMessage = "🚑 POLÍCIA: Polícia demorou! Motorista agredido, criminosos roubaram 30% da carga. Danos de 30% no chassi e atraso de 25 min."
                damageData.body = 300
                nextWait = 25 * 60
                MySQL.update.await('UPDATE trucker_drivers SET current_job_reward = current_job_reward * 0.7 WHERE driver_id = ?', { driverId })
            end
        end
    end
    
    if penaltyCost > 0 then 
        companyDebit(userId, penaltyCost) 
        MySQL.update.await('UPDATE trucker_drivers SET total_spent = total_spent + ? WHERE driver_id = ?', { penaltyCost, driverId }) 
    end
    
    MySQL.update.await([[UPDATE trucker_trucks SET engine = IF(engine > ?, engine - ?, 0), transmission = IF(transmission > ?, transmission - ?, 0), body = IF(body > ?, body - ?, 0), wheels = IF(wheels > ?, wheels - ?, 0) WHERE truck_id = ?]], { damageData.engine, damageData.engine, damageData.transmission, damageData.transmission, damageData.body, damageData.body, damageData.wheels, damageData.wheels, driver.truck_id })
    MySQL.update.await([[UPDATE trucker_drivers SET status = 'TRANSIT', timer = ?, pending_event_data = NULL, active_event = ? WHERE driver_id = ?]], { os.time() + nextWait, "Crise Resolvida", driverId })
    notify(source, resultMessage, "inform")
    
    if source then
        TriggerClientEvent('cidade_tycoon_tablet:client:showToast', source, '📉 EVENTO RESOLVIDO', resultMessage, 10000)
    end
    
    openUI(source, true)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:spawnTruck', function(truckId)
    local source = source
    local userId = citizenId(source)
    truckId = integer(truckId, 1)
    if not userId or not truckId then return end
    local truck = MySQL.single.await('SELECT * FROM trucker_trucks WHERE truck_id = ? AND user_id = ?', { truckId, userId })
    if truck and (truck.driver == nil or number(truck.driver) == 0) then
        TriggerClientEvent('cidade_tycoon_trucklogistics:spawnTruck', source, truck)
    end
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:upgradeSkill', function(data)
    local source = source
    local userId = citizenId(source)
    local skill = type(data) == 'table' and data.id or nil
    local value = type(data) == 'table' and integer(data.value, 0, 6) or nil
    if not userId or value == nil then return end
    local user = ensureUser(userId)
    local cost = value - number(user[skill])
    if cost <= 0 or number(user.skill_points) < cost then return end
    MySQL.update.await(('UPDATE trucker_users SET `%s` = ?, skill_points = skill_points - ? WHERE user_id = ?'):format(skill), { value, cost, userId })
    openUI(source, true)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:repairTruck', function(item)
    local source = source
    local userId = citizenId(source)
    if not userId then return end
    local truck = MySQL.single.await('SELECT * FROM trucker_trucks WHERE user_id = ? AND driver = 0 LIMIT 1', { userId })
    if not truck then return end
    local amount = math.floor((100 - number(truck[item]) / 10) * number(Config.valor_reparo[item]))
    if amount <= 0 then return end
    if not companyDebit(userId, amount) then return end
    MySQL.update.await(('UPDATE trucker_trucks SET `%s` = 1000 WHERE truck_id = ? AND user_id = ?'):format(item), { truck.truck_id, userId })
    openUI(source, true)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:buyTruck', function(data)
    local source = source
    local userId = citizenId(source)
    local name = type(data) == 'table' and tostring(data.truck_name) or nil
    if not userId or not Config.concessionaria[name] then return end
    if companyDebit(userId, Config.concessionaria[name].price) then
        MySQL.insert.await('INSERT INTO trucker_trucks (user_id, truck_name) VALUES (?, ?)', { userId, name })
        openUI(source, true)
    end
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:sellTruck', function(data)
    local source = source
    local userId = citizenId(source)
    local truckId = type(data) == 'table' and integer(data.truck_id, 1) or nil
    if not userId or not truckId then return end
    local truck = MySQL.single.await('SELECT * FROM trucker_trucks WHERE truck_id = ? AND user_id = ?', { truckId, userId })
    if truck and (truck.driver == nil or number(truck.driver) == 0) then
        local price = math.floor(Config.concessionaria[truck.truck_name].price * Config.multiplicador_venda)
        MySQL.update.await('DELETE FROM trucker_trucks WHERE truck_id = ?', { truckId })
        companyCredit(userId, price)
        openUI(source, true)
    end
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:hireDriver', function(driverId)
    local source = source
    local userId = citizenId(source)
    driverId = integer(driverId, 1)
    if not userId or not driverId then return end
    local driver = MySQL.single.await('SELECT * FROM trucker_drivers WHERE driver_id = ? AND user_id IS NULL', { driverId })
    if driver and companyDebit(userId, driver.price) then
        MySQL.update.await('UPDATE trucker_drivers SET user_id = ? WHERE driver_id = ?', { userId, driverId })
        openUI(source, true)
    end
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:fireDriver', function(driverId)
    local source = source
    local userId = citizenId(source)
    driverId = integer(driverId, 1)
    if not userId or not driverId then return end
    MySQL.update.await('UPDATE trucker_drivers SET user_id = NULL, level = 1, status = "IDLE", timer = 0, pending_event_data = NULL, route_events = NULL WHERE driver_id = ? AND user_id = ?', { driverId, userId })
    MySQL.update.await('UPDATE trucker_trucks SET driver = NULL WHERE driver = ?', { driverId })
    openUI(source, true)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:setDriver', function(data)
    local source = source
    local userId = citizenId(source)
    local driverId = type(data) == 'table' and tonumber(data.driver_id) or nil
    local truckId = type(data) == 'table' and integer(data.truck_id, 1) or nil
    if not userId or not truckId then return end
    
    if driverId == 0 then
        -- Primeiro, desvincula qualquer outro caminhão do usuário marcado como Uso Pessoal (driver = 0)
        MySQL.update.await('UPDATE trucker_trucks SET driver = NULL WHERE user_id = ? AND driver = 0', { userId })
        -- Agora define o caminhão selecionado como Uso Pessoal (driver = 0)
        MySQL.update.await('UPDATE trucker_trucks SET driver = 0 WHERE truck_id = ? AND user_id = ?', { truckId, userId })
    elseif data.driver_id == nil or data.driver_id == null or data.driver_id == 'null' then
        -- Se for para desmarcar (driver_id nulo/nil):
        MySQL.update.await('UPDATE trucker_trucks SET driver = NULL WHERE truck_id = ? AND user_id = ?', { truckId, userId })
    else
        -- Atribui ao motorista NPC contratado
        MySQL.update.await('UPDATE trucker_trucks SET driver = ? WHERE truck_id = ? AND user_id = ?', { driverId, truckId, userId })
        MySQL.update.await('UPDATE trucker_trucks SET driver = NULL WHERE driver = ? AND truck_id <> ?', { driverId, truckId })
    end
    openUI(source, true)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:depositMoney', function(data)
    local source = source
    local userId = citizenId(source)
    local amount = type(data) == 'table' and integer(data.amount, 1) or nil
    if not userId or not amount then return end
    if corePlayer(source).Functions.RemoveMoney('bank', amount) then
        companyCredit(userId, amount)
        openUI(source, true)
    end
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:withdrawMoney', function()
    local source = source
    local userId = citizenId(source)
    if not userId then return end
    local user = ensureUser(userId)
    local amount = number(user.money)
    if amount > 0 then
        MySQL.update.await('UPDATE trucker_users SET money = 0 WHERE user_id = ?', { userId })
        corePlayer(source).Functions.AddMoney('bank', amount)
        openUI(source, true)
    end
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:loan', function(data)
    local source = source
    local userId = citizenId(source)
    local loanId = type(data) == 'table' and integer(data.loan_id, 1, 4) or nil
    if not userId or not loanId then return end
    local l = Config.emprestimos.valores[loanId]
    companyCredit(userId, l[1])
    MySQL.insert.await('INSERT INTO trucker_loans (user_id, loan, remaining_amount, day_cost, taxes_on_day, timer) VALUES (?, ?, ?, ?, ?, ?)', { userId, l[1], l[1], l[2], l[2] - l[3], os.time() })
    openUI(source, true)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:payLoan', function(data)
    local source = source
    local userId = citizenId(source)
    local id = type(data) == 'table' and integer(data.loan_id, 1) or nil
    if not userId or not id then return end
    local loan = MySQL.single.await('SELECT * FROM trucker_loans WHERE id = ? AND user_id = ?', { id, userId })
    if loan and companyDebit(userId, number(loan.remaining_amount)) then
        MySQL.update.await('DELETE FROM trucker_loans WHERE id = ?', { id })
        openUI(source, true)
    end
end)

AddEventHandler('playerDropped', function()
    isOpen[source] = nil
    eventLocks[source] = nil
    activeJobs[source] = nil
end)
