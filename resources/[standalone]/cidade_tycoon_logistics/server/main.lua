local sharedConfig = require 'config.shared'

local CompanyCache = {}

local function getCompanyData(source)
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
    if not citizenId then return nil end

    if CompanyCache[citizenId] then
        return CompanyCache[citizenId]
    end

    local row = MySQL.single.await('SELECT * FROM tycoon_companies WHERE citizenid = ?', { citizenId })
    if not row then return nil end

    local company = {
        id = row.id,
        citizenid = row.citizenid,
        name = row.name,
        level = row.level,
        experience = row.experience,
        vaultBalance = row.vault_balance,
        warehouseId = row.warehouse_id,
        upgrades = row.upgrades and json.decode(row.upgrades) or {},
        isActive = row.is_active == 1
    }

    CompanyCache[citizenId] = company
    return company
end

local function addCompanyFunds(companyId, amount, reason)
    MySQL.update.await('UPDATE tycoon_companies SET vault_balance = vault_balance + ? WHERE id = ?', { amount, companyId })
    -- Clear cache if necessary or update it
    for _, comp in pairs(CompanyCache) do
        if comp.id == companyId then
            comp.vaultBalance = comp.vaultBalance + amount
            break
        end
    end
    return true
end

local function removeCompanyFunds(companyId, amount, reason)
    local row = MySQL.single.await('SELECT vault_balance FROM tycoon_companies WHERE id = ?', { companyId })
    if not row or row.vault_balance < amount then return false end

    MySQL.update.await('UPDATE tycoon_companies SET vault_balance = vault_balance - ? WHERE id = ?', { amount, companyId })
    -- Clear cache if necessary or update it
    for _, comp in pairs(CompanyCache) do
        if comp.id == companyId then
            comp.vaultBalance = comp.vaultBalance - amount
            break
        end
    end
    return true
end

local function getBusinessDashboardForSource(source)
    local company = getCompanyData(source)
    local allHubs = exports.cidade_tycoon_hubs:GetAllHubs()

    if not company then
        return { hasCompany = false, warehouses = allHubs }
    end

    -- Fetch Employees
    local employees = MySQL.query.await('SELECT * FROM tycoon_company_employees WHERE company_id = ?', { company.id })
    
    -- Fetch Fleet
    local fleet = MySQL.query.await('SELECT * FROM tycoon_company_fleet WHERE company_id = ?', { company.id })

    -- Fetch Active NPC Deliveries
    local activeDeliveries = MySQL.query.await('SELECT * FROM tycoon_npc_deliveries WHERE company_id = ? AND status = "in_progress"', { company.id })

    -- Fetch Production Lines
    local productionLines = {}
    if GetResourceState('cidade_tycoon_production') == 'started' then
        productionLines = MySQL.query.await('SELECT * FROM tycoon_production_lines WHERE company_id = ? AND status = "active"', { company.id })
    end

    return {
        hasCompany = true,
        company = company,
        employees = employees or {},
        fleet = fleet or {},
        activeDeliveries = activeDeliveries or {},
        productionLines = productionLines or {},
        warehouse = exports.cidade_tycoon_hubs:GetHubData(company.warehouseId)
    }
end

local function getAvailableJobsForSource(source)
    return MySQL.query.await('SELECT j.*, c.name as company_name FROM tycoon_job_board j JOIN tycoon_companies c ON j.company_id = c.id WHERE j.status = "posted"')
end

-- Callbacks for UI
lib.callback.register('cidade_tycoon_logistics:server:getBusinessDashboard', getBusinessDashboardForSource)

lib.callback.register('cidade_tycoon_logistics:server:purchaseCompany', function(source, warehouseId, name)
    local company = getCompanyData(source)
    if company then return { ok = false, message = 'Voce ja possui uma empresa.' } end

    local warehouse = exports.cidade_tycoon_hubs:GetHubData(warehouseId)
    if not warehouse then return { ok = false, message = 'Galpão/Hub invalido.' } end

    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local price = warehouse.purchasePrice or 250000

    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < price then
        return { ok = false, message = ('Saldo bancario insuficiente ($%d necessario).'):format(price) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', price, 'tycoon-company-purchase') then
        local citizenId = exports.cidade_tycoon_core:GetCitizenId(player)
        
        local insertId = MySQL.insert.await([[
            INSERT INTO tycoon_companies (citizenid, name, warehouse_id, vault_balance)
            VALUES (?, ?, ?, ?)
        ]], { citizenId, name or 'Logística Tycoon', warehouseId, 0 })

        if insertId then
            exports.cidade_tycoon_core:LogTransaction(source, price, 'expense', 'purchase', 'Fundação de Empresa: ' .. warehouse.name)
            return { ok = true, message = 'Empresa fundada com sucesso! Bem-vindo ao topo.' }
        end
    end

    return { ok = false, message = 'Falha no processamento.' }
end)

lib.callback.register('cidade_tycoon_logistics:server:recruitEmployee', function(source, level)
    local company = getCompanyData(source)
    if not company then return { ok = false, message = 'Empresa nao encontrada.' } end

    local recruitmentDef = sharedConfig.npcRecruitment.levels[level]
    if not recruitmentDef then return { ok = false, message = 'Nivel de recrutamento invalido.' } end

    local cost = sharedConfig.npcRecruitment.baseCost * recruitmentDef.multiplier
    
    local player = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if exports.cidade_tycoon_core:GetMoneyBalance(player, 'bank') < cost then
        return { ok = false, message = ('Saldo insuficiente. Custo: $%d'):format(cost) }
    end

    if exports.cidade_tycoon_core:RemoveMoney(player, 'bank', cost, 'tycoon-npc-recruitment') then
        local names = { "João", "Carlos", "Ricardo", "Roberto", "Marcos", "Antônio" }
        local randomName = names[math.random(#names)] .. " " .. string.char(math.random(65, 90)) .. "."
        
        local insertId = MySQL.insert.await([[
            INSERT INTO tycoon_company_employees (company_id, name, skill_level, salary)
            VALUES (?, ?, ?, ?)
        ]], { company.id, randomName, level, recruitmentDef.salary })

        if insertId then
            exports.cidade_tycoon_core:LogTransaction(source, cost, 'expense', 'recruitment', 'Recrutamento de Motorista: ' .. randomName)
            return { ok = true, message = ('%s foi contratado para sua equipe!'):format(randomName) }
        end
    end

    return { ok = false, message = 'Falha ao contratar.' }
end)

lib.callback.register('cidade_tycoon_logistics:server:postJob', function(source, title, reward, cargoType)
    local company = getCompanyData(source)
    if not company then return { ok = false, message = 'Empresa nao encontrada.' } end

    if company.vaultBalance < reward then
        return { ok = false, message = 'Saldo da empresa insuficiente para pagar o freelancer.' }
    end

    if reward < 2000 then
        return { ok = false, message = 'A recompensa minima para um contrato corporativo é $2.000.' }
    end

    -- Fetch dynamic location from Hubs and Freelance
    local warehouse = exports.cidade_tycoon_hubs:GetHubData(company.warehouseId)
    if not warehouse then return { ok = false, message = 'Erro ao localizar seu galpão.' } end

    -- Deduct reward immediately to guarantee payment (Escrow)
    if removeCompanyFunds(company.id, reward, 'Publicação de Vaga Freelancer') then
        local origin = warehouse.coords
        
        -- Pick random destination from freelance points (land mode)
        local freelancePoints = exports.cidade_tycoon_freelance:GetSharedPoints('land')
        local dest = freelancePoints[math.random(#freelancePoints)]

        local insertId = MySQL.insert.await([[
            INSERT INTO tycoon_job_board (company_id, title, reward, cargo_type, origin_coords, dest_coords)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], { company.id, title, reward, cargoType, json.encode({x = origin.x, y = origin.y, z = origin.z}), json.encode({x = dest.x, y = dest.y, z = dest.z}) })

        if insertId then
            exports.cidade_tycoon_core:LogTransaction(source, reward, 'expense', 'logistics', 'Publicação de Contrato: ' .. title)
            return { ok = true, message = 'Vaga publicada no mural de empregos! O valor foi retido para garantia de pagamento.' }
        end
    end

    return { ok = false, message = 'Falha ao publicar vaga.' }
end)

lib.callback.register('cidade_tycoon_logistics:server:getAvailableJobs', function(source)
    return MySQL.query.await('SELECT j.*, c.name as company_name FROM tycoon_job_board j JOIN tycoon_companies c ON j.company_id = c.id WHERE j.status = "posted"')
end)

-- Exports
exports('GetCompanyData', getCompanyData)
exports('AddCompanyFunds', addCompanyFunds)
exports('RemoveCompanyFunds', removeCompanyFunds)
exports('GetBusinessDashboardForSource', getBusinessDashboardForSource)
exports('GetAvailableJobsForSource', getAvailableJobsForSource)
