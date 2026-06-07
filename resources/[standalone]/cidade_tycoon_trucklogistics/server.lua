local RESOURCE = GetCurrentResourceName()
local isOpen = {}
local eventLocks = {}
local activeJobs = {}

local function corePlayer(source)
    return exports.cidade_tycoon_core:GetFrameworkPlayer(source)
end

local function citizenId(source)
    local player = corePlayer(source)
    return player and exports.cidade_tycoon_core:GetCitizenId(player) or nil
end

local function notify(source, message, notifyType)
    local kind = notifyType == 'primary' and 'inform' or (notifyType or 'inform')
    exports.cidade_tycoon_core:NotifyPlayer(source, message, kind)
end

local function sendWebhook(message)
    if type(Config.webhook) ~= 'string' or Config.webhook == '' then return end
    PerformHttpRequest(Config.webhook, function() end, 'POST', json.encode({ content = message }), {
        ['Content-Type'] = 'application/json'
    })
end

local function number(value, fallback)
    if value == nil then return fallback or 0 end
    if type(value) == 'number' then return value end
    if value == true then return 1 end
    if value == false then return 0 end
    local n = tonumber(value)
    if n then return n end
    if type(value) == 'string' and #value == 1 then return string.byte(value) end
    return fallback or 0
end

local function integer(value, minimum, maximum)
    local n = number(value, nil)
    if not n then return nil end
    n = math.floor(n)
    if minimum and n < minimum then return nil end
    if maximum and n > maximum then return nil end
    return n
end

local function withLock(source, callback)
    if eventLocks[source] then return end
    eventLocks[source] = true
    local ok, err = xpcall(callback, debug.traceback)
    eventLocks[source] = nil
    if not ok then
        print(('^1[%s]^7 %s'):format(RESOURCE, err))
        notify(source, 'Nao foi possivel concluir a operacao.', 'error')
    end
end

local function ensureUser(userId)
    MySQL.insert.await('INSERT IGNORE INTO trucker_users (user_id) VALUES (?)', { userId })
    return MySQL.single.await('SELECT * FROM trucker_users WHERE user_id = ?', { userId })
end

local function companyCredit(userId, amount)
    amount = math.floor(number(amount))
    if amount <= 0 then return false end
    ensureUser(userId)
    return MySQL.update.await('UPDATE trucker_users SET money = money + ? WHERE user_id = ?', { amount, userId }) > 0
end

local function companyDebit(userId, amount)
    amount = math.floor(number(amount))
    if amount <= 0 then return false end
    ensureUser(userId)
    return MySQL.update.await('UPDATE trucker_users SET money = money - ? WHERE user_id = ? AND money >= ?', {
        amount, userId, amount
    }) > 0
end

local function playerSourceByCitizenId(userId)
    userId = tostring(userId)
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source and citizenId(source) == userId then return source end
    end
end

local function getPlayerLevel(userId)
    local row = MySQL.single.await('SELECT exp FROM trucker_users WHERE user_id = ?', { userId })
    local experience = row and number(row.exp) or 0
    local level = 0
    for index, required in pairs(Config.exp_por_level) do
        index = number(index)
        if experience >= number(required) and index > level then level = index end
    end
    return level
end

local function getMaxLoan(userId)
    local level = getPlayerLevel(userId)
    local maximum = 0
    for requiredLevel, amount in pairs(Config.max_emprestimo_por_level) do
        if number(requiredLevel) <= level then maximum = math.max(maximum, number(amount)) end
    end
    return maximum
end

local function clone(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for key, child in pairs(value) do result[clone(key)] = clone(child) end
    return result
end

local function openUI(source, reset)
    local userId = citizenId(source)
    if not userId then return end

    local user = ensureUser(userId)
    if not user then return end
    if number(user.loan_notify) == 1 then
        MySQL.update.await('UPDATE trucker_users SET loan_notify = 0 WHERE user_id = ?', { userId })
        notify(source, Lang[Config.lang].no_loan_money, 'inform')
        user.loan_notify = 0
    end

    local payload = {
        trucker_users = user,
        trucker_available_contracts = MySQL.query.await('SELECT * FROM trucker_available_contracts', {}),
        trucker_trucks = MySQL.query.await('SELECT * FROM trucker_trucks WHERE user_id = ?', { userId }),
        trucker_drivers = MySQL.query.await('SELECT * FROM trucker_drivers WHERE user_id = ? OR user_id IS NULL', { userId }),
        trucker_loans = MySQL.query.await('SELECT * FROM trucker_loans WHERE user_id = ?', { userId }),
        config = {
            concessionaria = clone(Config.concessionaria),
            formatacao = clone(Config.formatacao),
            valor_reparo = clone(Config.valor_reparo),
            exp_por_level = clone(Config.exp_por_level),
            max_emprestimo_por_level = clone(Config.max_emprestimo_por_level),
            emprestimos = clone(Config.emprestimos.valores),
            cooldown = Config.contratos.cooldown,
            max_emprestimo = getMaxLoan(userId),
            player_level = getPlayerLevel(userId)
        }
    }
    TriggerClientEvent('cidade_tycoon_trucklogistics:open', source, payload, reset == true)
end

local function refreshOpenPlayers()
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source and isOpen[source] then
            openUI(source, true)
            Wait(50)
        end
    end
end

local function contractDistance(contract, empresaId)
    local destination = Config.locais_entrega[integer(contract.coords_index, 1)]
    if not destination then return nil end
    local company = Config.empresas[empresaId]
    if not company then
        local _, firstCompany = next(Config.empresas)
        company = firstCompany
    end
    if not company or not company.coordenada then return nil end
    local origin = company.coordenada
    return #(vec3(origin[1], origin[2], origin[3]) - vec3(destination[1], destination[2], destination[3])) / 1000.0
end

local function restoreActiveContract(source)
    local job = activeJobs[source]
    if not job then return end
    activeJobs[source] = nil
    local contract = job.contract
    MySQL.insert.await([[INSERT IGNORE INTO trucker_available_contracts
        (contract_id, contract_type, contract_name, coords_index, price_per_km, cargo_type, fragile, valuable, fast, truck, trailer)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        contract.contract_id, contract.contract_type, contract.contract_name, contract.coords_index,
        contract.price_per_km, contract.cargo_type, contract.fragile, contract.valuable,
        contract.fast, contract.truck, contract.trailer
    })
    refreshOpenPlayers()
end

local function logWithUser(template, userId, ...)
    if type(template) ~= 'string' then return end
    local arguments = { ... }
    arguments[#arguments + 1] = userId .. os.date('\n[' .. Lang[Config.lang].logs_date .. ']: %d/%m/%Y [' .. Lang[Config.lang].logs_hour .. ']: %H:%M:%S')
    sendWebhook(template:format(table.unpack(arguments)))
end

local function generateContract()
    local maxContracts = number(Config.contratos.max_contratos_ativos, 60)
    local count = number(MySQL.scalar.await('SELECT COUNT(*) FROM trucker_available_contracts'))
    if count >= maxContracts then
        MySQL.update.await([[DELETE FROM trucker_available_contracts
            WHERE contract_id = (SELECT contract_id FROM (SELECT MIN(contract_id) contract_id FROM trucker_available_contracts) oldest)]])
    end

    local contractType = math.random(0, 1)
    local bonus = contractType == 0 and number(Config.contratos.multiplicador_frete, 1.1) or 1.0
    local cargo = Config.contratos.cargas[math.random(#Config.contratos.cargas)]
    local truck = contractType == 0 and Config.contratos.caminhoes[math.random(#Config.contratos.caminhoes)] or nil

    local priceMin = number(Config.contratos.preco_por_km_min, 150)
    local priceMax = number(Config.contratos.preco_por_km_max, 300)

    MySQL.insert.await([[INSERT INTO trucker_available_contracts
        (contract_type, contract_name, coords_index, price_per_km, cargo_type, fragile, valuable, fast, truck, trailer)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        contractType,
        cargo.nome,
        math.random(#Config.locais_entrega),
        math.floor(math.random(priceMin, priceMax) * bonus),
        cargo.def[1], cargo.def[2], cargo.def[3],
        math.random(100) <= number(Config.contratos.probabilidade_ser_cargo_urgente, 10) and 1 or 0,
        truck, cargo.carga
    })
end

local function generateDriver()
    local maxDriversActive = number(Config.motoristas.max_motoristas_ativos, 20)
    local count = number(MySQL.scalar.await('SELECT COUNT(*) FROM trucker_drivers WHERE user_id IS NULL'))
    if count >= maxDriversActive then
        MySQL.update.await([[DELETE FROM trucker_drivers
            WHERE driver_id = (SELECT driver_id FROM (SELECT MIN(driver_id) driver_id FROM trucker_drivers WHERE user_id IS NULL) oldest)]])
    end

    local skills = {
        product_type = math.random(0, 6), distance = math.random(0, 6), fragile = math.random(0, 6),
        valuable = math.random(0, 6), fast = math.random(0, 6)
    }
    local total = skills.product_type + skills.distance + skills.fragile + skills.valuable + skills.fast
    if total > 20 then
        for key in pairs(skills) do skills[key] = math.random(0, 4) end
        total = skills.product_type + skills.distance + skills.fragile + skills.valuable + skills.fast
    end
    local driverGroup = Config.motoristas.nomes[math.random(#Config.motoristas.nomes)]
    local price = math.random(Config.motoristas.preco_min, Config.motoristas.preco_max)
    local pricePerKm = math.random(Config.motoristas.preco_por_km_min, Config.motoristas.preco_por_km_max)
    local multiplier = 1 + total * (Config.motoristas.porcentagem_bonus_habilidades / 100)
    
    local imgUrl = driverGroup.img
    if imgUrl:find('bootdey.com') then
        local matchNum = imgUrl:match('avatar(%d)%.png')
        if matchNum then
            imgUrl = 'img/avatar' .. matchNum .. '.png'
        else
            imgUrl = 'img/avatar1.png'
        end
    end

    MySQL.insert.await([[INSERT INTO trucker_drivers
        (user_id, name, product_type, distance, fragile, valuable, fast, price, price_per_km, img)
        VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        driverGroup.nomes[math.random(#driverGroup.nomes)], skills.product_type, skills.distance, skills.fragile,
        skills.valuable, skills.fast, math.floor(price * multiplier), math.floor(pricePerKm * multiplier), imgUrl
    })
end

-- Seeding and periodic generation threads
CreateThread(function()
    Wait(5000)
    -- Seed initial drivers on startup if empty
    local driversCount = number(MySQL.scalar.await('SELECT COUNT(*) FROM trucker_drivers WHERE user_id IS NULL'))
    if driversCount < 6 then
        local toGenerate = 6 - driversCount
        print(('[%s] Seeding %d initial drivers...'):format(RESOURCE, toGenerate))
        for i = 1, toGenerate do
            generateDriver()
        end
        refreshOpenPlayers()
    end

    -- Seed initial contracts on startup if empty
    local contractsCount = number(MySQL.scalar.await('SELECT COUNT(*) FROM trucker_available_contracts'))
    if contractsCount < 12 then
        local toGenerate = 12 - contractsCount
        print(('[%s] Seeding %d initial contracts...'):format(RESOURCE, toGenerate))
        for i = 1, toGenerate do
            generateContract()
        end
        refreshOpenPlayers()
    end
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
        local drivers = MySQL.query.await([[SELECT d.driver_id, d.user_id, d.name, d.product_type, d.distance,
            d.valuable, d.fragile, d.fast, d.price, d.price_per_km
            FROM trucker_trucks t INNER JOIN trucker_drivers d ON t.driver = d.driver_id
            WHERE t.driver IS NOT NULL AND t.driver <> 0]], {})
        for _, driver in ipairs(drivers) do
            local source = playerSourceByCitizenId(driver.user_id)
            if Config.trabalhos.gera_dinheiro_offline or source then
                local cost = number(driver.price) + number(driver.price_per_km)
                if companyDebit(driver.user_id, cost) then
                    local skillTotal = number(driver.product_type) + number(driver.distance) + number(driver.fragile)
                        + number(driver.valuable) + number(driver.fast)
                    local amount = math.random(Config.trabalhos.valor_inicial_min, Config.trabalhos.valor_inicial_max)
                    amount = math.floor(amount * (1 + skillTotal * Config.trabalhos.porcentagem_bonus_habilidades / 100))
                    companyCredit(driver.user_id, amount)
                else
                    MySQL.update.await('UPDATE trucker_drivers SET user_id = NULL WHERE driver_id = ?', { driver.driver_id })
                    MySQL.update.await('UPDATE trucker_trucks SET driver = NULL WHERE driver = ?', { driver.driver_id })
                    if source then notify(source, Lang[Config.lang].driver_failed:format(driver.name), 'error') end
                end
                if source and isOpen[source] then openUI(source, true) end
            end
            Wait(50)
        end
        Wait(Config.trabalhos.cooldown * 60000)
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
                        MySQL.update.await('UPDATE trucker_loans SET remaining_amount = ?, timer = ? WHERE id = ?', {
                            remaining, os.time(), loan.id
                        })
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
        if number(Config.habilidade_distancia[number(user.distance)]) < distance then
            return notify(source, Lang[Config.lang].no_skill_1, 'error')
        end

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
        activeJobs[source] = {
            userId = userId,
            contract = contract,
            distance = distance,
            reward = reward,
            truck = truck,
            startedAt = os.time()
        }
        TriggerClientEvent('cidade_tycoon_trucklogistics:startContract', source, contract, distance, reward, truck)
        refreshOpenPlayers()
    end)
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
    local allowed = { product_type = true, distance = true, valuable = true, fragile = true, fast = true }
    local skill = type(data) == 'table' and data.id or nil
    local value = type(data) == 'table' and integer(data.value, 0, 6) or nil
    if not userId or not allowed[skill] or value == nil then return end
    local user = ensureUser(userId)
    local current = number(user[skill])
    local cost = value - current
    if cost <= 0 or number(user.skill_points) < cost then return notify(source, Lang[Config.lang].insufficient_skill_points, 'error') end
    MySQL.update.await(('UPDATE trucker_users SET `%s` = ?, skill_points = skill_points - ? WHERE user_id = ?'):format(skill), {
        value, cost, userId
    })
    notify(source, Lang[Config.lang].upgraded_skill, 'success')
    openUI(source, true)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:repairTruck', function(item)
    local source = source
    local userId = citizenId(source)
    local allowed = { body = true, engine = true, transmission = true, wheels = true }
    if not userId or not allowed[item] then return end
    local truck = MySQL.single.await('SELECT * FROM trucker_trucks WHERE user_id = ? AND (driver IS NULL OR driver = 0) LIMIT 1', { userId })
    if not truck then return notify(source, Lang[Config.lang].have_no_truck, 'error') end
    local amount = math.floor((100 - number(truck[item]) / 10) * number(Config.valor_reparo[item]))
    if amount <= 0 then return notify(source, Lang[Config.lang].not_repaired, 'error') end
    if not companyDebit(userId, amount) then return notify(source, Lang[Config.lang].insufficiente_funds, 'error') end
    MySQL.update.await(('UPDATE trucker_trucks SET `%s` = 1000 WHERE truck_id = ? AND user_id = ?'):format(item), {
        truck.truck_id, userId
    })
    notify(source, Lang[Config.lang].repaired, 'success')
    openUI(source, true)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:buyTruck', function(data)
    local source = source
    withLock(source, function()
        local userId = citizenId(source)
        local model = type(data) == 'table' and tostring(data.truck_name or '') or ''
        local definition = Config.concessionaria[model]
        if not userId or not definition then return end
        local price = math.floor(number(definition.price))
        if not companyDebit(userId, price) then return notify(source, Lang[Config.lang].insufficiente_funds, 'error') end
        MySQL.insert.await('INSERT INTO trucker_trucks (user_id, truck_name, driver) VALUES (?, ?, NULL)', { userId, model })
        notify(source, Lang[Config.lang].bought, 'success')
        logWithUser(Lang[Config.lang].logs_buytruck, userId, model, price)
        openUI(source, true)
    end)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:sellTruck', function(data)
    local source = source
    withLock(source, function()
        local userId = citizenId(source)
        local truckId = type(data) == 'table' and integer(data.truck_id, 1) or nil
        if not userId or not truckId then return end
        local truck = MySQL.single.await('SELECT * FROM trucker_trucks WHERE truck_id = ? AND user_id = ?', { truckId, userId })
        local definition = truck and Config.concessionaria[truck.truck_name] or nil
        if not truck or not definition then return end
        if MySQL.update.await('DELETE FROM trucker_trucks WHERE truck_id = ? AND user_id = ?', { truckId, userId }) == 0 then return end
        local amount = math.floor(number(definition.price) * number(Config.multiplicador_venda))
        companyCredit(userId, amount)
        notify(source, Lang[Config.lang].sold, 'success')
        logWithUser(Lang[Config.lang].logs_selltruck, userId, truck.truck_name, amount)
        openUI(source, true)
    end)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:hireDriver', function(driverId)
    local source = source
    withLock(source, function()
        local userId = citizenId(source)
        driverId = integer(driverId, 1)
        if not userId or not driverId then return end
        local count = number(MySQL.scalar.await('SELECT COUNT(*) FROM trucker_drivers WHERE user_id = ?', { userId }))
        if count >= Config.motoristas.max_motoristas_por_player then return notify(source, Lang[Config.lang].max_drivers, 'error') end
        local driver = MySQL.single.await('SELECT * FROM trucker_drivers WHERE driver_id = ? AND user_id IS NULL', { driverId })
        if not driver then return notify(source, 'Motorista nao encontrado ou ja contratado.', 'error') end
        if not companyDebit(userId, driver.price) then return notify(source, Lang[Config.lang].insufficiente_funds, 'error') end
        if MySQL.update.await('UPDATE trucker_drivers SET user_id = ? WHERE driver_id = ? AND user_id IS NULL', { userId, driverId }) == 0 then
            companyCredit(userId, driver.price)
            return
        end
        notify(source, Lang[Config.lang].hired, 'success')
        openUI(source, true)
    end)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:fireDriver', function(driverId)
    local source = source
    local userId = citizenId(source)
    driverId = integer(driverId, 1)
    if not userId or not driverId then return end
    MySQL.update.await('UPDATE trucker_trucks SET driver = NULL WHERE user_id = ? AND driver = ?', { userId, driverId })
    if MySQL.update.await('UPDATE trucker_drivers SET user_id = NULL WHERE driver_id = ? AND user_id = ?', { driverId, userId }) > 0 then
        notify(source, Lang[Config.lang].fired, 'success')
        openUI(source, true)
    end
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:setDriver', function(data)
    local source = source
    print("^3[TruckLogistics:Debug:Server]^7 Recebido setDriver de " .. source .. ": " .. json.encode(data))
    local userId = citizenId(source)
    local truckId = type(data) == 'table' and integer(data.truck_id, 1) or nil
    
    print("^3[TruckLogistics:Debug:Server]^7 Processando: userId=" .. tostring(userId) .. ", truckId=" .. tostring(truckId))

    local driverId = nil
    local hasDriverId = false
    if type(data) == 'table' and data.driver_id ~= nil then
        driverId = integer(data.driver_id, 0)
        hasDriverId = true
        print("^3[TruckLogistics:Debug:Server]^7 driverId convertido para: " .. tostring(driverId))
    end

    if not userId or not truckId or (hasDriverId and driverId == nil) then 
        print("^1[TruckLogistics:Debug:Server]^7 Falha na validação inicial dos dados.")
        return 
    end
    
    local truck = MySQL.single.await('SELECT truck_id FROM trucker_trucks WHERE truck_id = ? AND user_id = ?', { truckId, userId })
    if not truck then 
        print("^1[TruckLogistics:Debug:Server]^7 Caminhão " .. tostring(truckId) .. " não encontrado para o usuário " .. tostring(userId))
        notify(source, "Caminhão não encontrado em sua frota.", "error")
        return 
    end
    
    print("^3[TruckLogistics:Debug:Server]^7 Caminhão validado com sucesso.")

    if driverId and driverId > 0 then
        local driver = MySQL.single.await('SELECT driver_id FROM trucker_drivers WHERE driver_id = ? AND user_id = ?', { driverId, userId })
        if not driver then return end
        MySQL.update.await('UPDATE trucker_trucks SET driver = NULL WHERE user_id = ? AND driver = ?', { userId, driverId })
    end
    
    if driverId == 0 then
        -- Clear player driving state (driver = 0) from any other owned truck
        MySQL.update.await('UPDATE trucker_trucks SET driver = NULL WHERE user_id = ? AND driver = 0', { userId })
        notify(source, "Veículo selecionado para uso pessoal e diagnóstico.", "success")
        print("^2[TruckLogistics:Debug:Server]^7 Veículo " .. truckId .. " selecionado para o jogador.")
    elseif driverId == nil then
        notify(source, "Veículo desmarcado.", "inform")
        print("^2[TruckLogistics:Debug:Server]^7 Veículo " .. truckId .. " desmarcado.")
    end
    
    local affectedRows = MySQL.update.await('UPDATE trucker_trucks SET driver = ? WHERE truck_id = ? AND user_id = ?', {
        driverId, truckId, userId
    })
    print("^3[TruckLogistics:Debug:Server]^7 Update concluído. Linhas afetadas: " .. tostring(affectedRows))

    openUI(source, true)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:depositMoney', function(data)
    local source = source
    withLock(source, function()
        local userId = citizenId(source)
        local amount = type(data) == 'table' and integer(data.amount, 1) or nil
        if not userId or not amount then return notify(source, Lang[Config.lang].invalid_value, 'error') end
        local balance = exports.cidade_tycoon_core:GetMoneyBalance(source, 'bank')
        if balance < amount then
            return notify(source, Lang[Config.lang].insufficiente_money, 'error')
        end
        if not exports.cidade_tycoon_core:RemoveMoney(source, 'bank', amount, 'trucker-cost') then
            return notify(source, Lang[Config.lang].insufficiente_money, 'error')
        end
        if not companyCredit(userId, amount) then
            exports.cidade_tycoon_core:AddMoney(source, 'bank', amount, 'trucker-refund')
            return notify(source, 'Falha ao atualizar o saldo da empresa.', 'error')
        end
        notify(source, Lang[Config.lang].money_deposited, 'success')
        openUI(source, true)
    end)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:withdrawMoney', function()
    local source = source
    withLock(source, function()
        local userId = citizenId(source)
        if not userId then return end
        local debt = number(MySQL.scalar.await('SELECT COALESCE(SUM(remaining_amount), 0) FROM trucker_loans WHERE user_id = ?', { userId }))
        if debt > 0 then return notify(source, Lang[Config.lang].pay_loans, 'error') end
        local user = ensureUser(userId)
        local amount = math.floor(number(user.money))
        if amount <= 0 then return notify(source, Lang[Config.lang].insufficiente_money, 'error') end
        if not companyDebit(userId, amount) then return end
        if not exports.cidade_tycoon_core:AddMoney(source, 'bank', amount, 'trucker-reward') then
            companyCredit(userId, amount)
            return notify(source, 'Falha ao transferir para o banco.', 'error')
        end
        notify(source, Lang[Config.lang].money_withdrawn, 'success')
        openUI(source, true)
    end)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:loan', function(data)
    local source = source
    withLock(source, function()
        local userId = citizenId(source)
        local loanId = type(data) == 'table' and integer(data.loan_id, 1) or nil
        local definition = loanId and Config.emprestimos.valores[loanId] or nil
        if not userId or not definition then return end
        local current = number(MySQL.scalar.await('SELECT COALESCE(SUM(loan), 0) FROM trucker_loans WHERE user_id = ?', { userId }))
        if current + number(definition[1]) > getMaxLoan(userId) then return notify(source, Lang[Config.lang].no_loan, 'error') end
        MySQL.insert.await([[INSERT INTO trucker_loans (user_id, loan, remaining_amount, day_cost, taxes_on_day, timer)
            VALUES (?, ?, ?, ?, ?, ?)]], { userId, definition[1], definition[1], definition[2], definition[3], os.time() })
        companyCredit(userId, definition[1])
        notify(source, Lang[Config.lang].loan, 'success')
        openUI(source, true)
    end)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:payLoan', function(data)
    local source = source
    withLock(source, function()
        local userId = citizenId(source)
        local loanId = type(data) == 'table' and integer(data.loan_id, 1) or nil
        if not userId or not loanId then return end
        local loan = MySQL.single.await('SELECT * FROM trucker_loans WHERE id = ? AND user_id = ?', { loanId, userId })
        if not loan or not companyDebit(userId, loan.remaining_amount) then return notify(source, Lang[Config.lang].insufficiente_funds, 'error') end
        MySQL.update.await('DELETE FROM trucker_loans WHERE id = ? AND user_id = ?', { loanId, userId })
        notify(source, Lang[Config.lang].loan_paid, 'success')
        openUI(source, true)
    end)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:finishJob', function(_, _, _, _, truckEngine, truckBody, trailerBody)
    local source = source
    withLock(source, function()
        local job = activeJobs[source]
        local userId = citizenId(source)
        if not job or not userId or job.userId ~= userId then return end
        local destination = Config.locais_entrega[integer(job.contract.coords_index, 1)]
        local ped = GetPlayerPed(source)
        if not destination or ped == 0 or os.time() - job.startedAt < 15 then return end
        local playerCoords = GetEntityCoords(ped)
        if #(playerCoords - vec3(destination[1], destination[2], destination[3])) > 50.0 then return end
        activeJobs[source] = nil
        local user = ensureUser(userId)
        local condition = math.max(0.0, math.min(number(trailerBody, 0) / 1000.0, 1.0))
        if condition <= 0.15 then return notify(source, Lang[Config.lang].failed, 'error') end
        local contract, reward, distance = job.contract, job.reward, job.distance
        local baseExperience = reward * (Config.exp / 100)
        local moneyBonus, experienceBonus = 0, 0
        local function addBonus(key, enabled)
            if number(enabled) <= 0 then return end
            local skill = number(user[key])
            moneyBonus = moneyBonus + reward * (number(Config.bonus[key].dinheiro[skill]) / 100)
            experienceBonus = experienceBonus + baseExperience * (number(Config.bonus[key].exp[skill]) / 100)
        end
        addBonus('fragile', contract.fragile)
        addBonus('valuable', contract.valuable)
        addBonus('fast', contract.fast)
        if distance > number(Config.habilidade_distancia[0]) then addBonus('distance', 1) end
        local receivedAmount = math.floor((reward + moneyBonus) * condition)
        local receivedExperience = math.floor((baseExperience + experienceBonus) * condition)
        local oldLevel = getPlayerLevel(userId)

        if job.truck and job.truck.truck_id then
            local engine = math.max(0, math.min(number(truckEngine), 1000))
            local body = math.max(0, math.min(number(truckBody), 1000))
            MySQL.update.await([[UPDATE trucker_trucks SET engine = ?, transmission = ?, body = ?,
                wheels = GREATEST(0, wheels - ?) WHERE truck_id = ? AND user_id = ?]], {
                engine, math.floor((engine + body) / 2), body, math.floor(distance * 10), job.truck.truck_id, userId
            })
        end
        MySQL.update.await([[UPDATE trucker_users SET total_earned = total_earned + ?,
            finished_deliveries = finished_deliveries + 1, traveled_distance = traveled_distance + ?, exp = exp + ?
            WHERE user_id = ?]], { receivedAmount, distance, receivedExperience, userId })
        companyCredit(userId, receivedAmount)
        notify(source, Lang[Config.lang].reward:format(receivedAmount, math.floor(condition * 100), receivedExperience), 'success')
        local gainedLevels = getPlayerLevel(userId) - oldLevel
        if gainedLevels > 0 then
            MySQL.update.await('UPDATE trucker_users SET skill_points = skill_points + ? WHERE user_id = ?', { gainedLevels, userId })
            logWithUser(Lang[Config.lang].logs_skill, userId, gainedLevels)
        end
        logWithUser(Lang[Config.lang].logs_finish, userId, receivedAmount, receivedExperience)
    end)
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:updateTruckStatus', function(truckData, truckEngine, truckBody)
    local source = source
    local userId = citizenId(source)
    local truckId = type(truckData) == 'table' and integer(truckData.truck_id, 1) or nil
    if not userId or not truckId then return end
    local engine = math.max(0, math.min(number(truckEngine), 1000))
    local body = math.max(0, math.min(number(truckBody), 1000))
    MySQL.update.await('UPDATE trucker_trucks SET engine = ?, transmission = ?, body = ? WHERE truck_id = ? AND user_id = ?', {
        engine, math.floor((engine + body) / 2), body, truckId, userId
    })
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:deleteContract', function()
    -- Contract consumption is server-authoritative in startContract.
end)

RegisterNetEvent('cidade_tycoon_trucklogistics:cancelContract', function()
    restoreActiveContract(source)
end)

AddEventHandler('playerDropped', function()
    isOpen[source] = nil
    eventLocks[source] = nil
    restoreActiveContract(source)
end)
