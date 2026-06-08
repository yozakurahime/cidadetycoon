local activeBuckets = {}

-- Safety check for MySQL global
if not MySQL then
    MySQL = exports.oxmysql
end

local function DebugLog(text, ...)
    print(string.format("^5[Tycoon:Production:Server]^7 %s", string.format(text, ...)))
end

local function setPlayerToCompanyBucket(source, companyId)
    local bucket = companyId + 100 
    SetPlayerRoutingBucket(source, bucket)
    activeBuckets[source] = bucket
    DebugLog("Jogador %d movido para Dimensão %d (Empresa %d)", source, bucket, companyId)
end

local function resetPlayerBucket(source)
    SetPlayerRoutingBucket(source, 0)
    activeBuckets[source] = nil
    DebugLog("Jogador %d retornou para Dimensão Global (0)", source)
end

-- ==========================================
-- DATABASE INITIALIZATION
-- ==========================================
CreateThread(function()
    Wait(2000) 
    
    -- Tabela Principal de Empresas (Padronizada)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tycoon_companies (
            id INT NOT NULL AUTO_INCREMENT,
            citizenid VARCHAR(50) NOT NULL,
            name VARCHAR(80) NOT NULL DEFAULT 'Nova Empresa',
            level INT DEFAULT 1,
            experience INT DEFAULT 0,
            vault_balance BIGINT NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY (citizenid)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Garante consistência de colunas (Caso criada pelo Logistics ou versão antiga)
    MySQL.query.await([[
        ALTER TABLE `tycoon_companies` 
        ADD COLUMN IF NOT EXISTS `experience` INT DEFAULT 0 AFTER `level`,
        ADD COLUMN IF NOT EXISTS `vault_balance` BIGINT NOT NULL DEFAULT 0 AFTER `experience`,
        ADD COLUMN IF NOT EXISTS `primary_product` VARCHAR(50) DEFAULT NULL AFTER `vault_balance`,
        ADD COLUMN IF NOT EXISTS `secondary_product` VARCHAR(50) DEFAULT NULL AFTER `primary_product`;
    ]])

    -- Tabela de Cargos Customizados
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tycoon_company_ranks (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            name VARCHAR(50) NOT NULL,
            permission_level INT DEFAULT 0,
            PRIMARY KEY (id),
            CONSTRAINT fk_rank_company FOREIGN KEY (company_id) REFERENCES tycoon_companies(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Tabela de Funcionários e Membros
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tycoon_company_members (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            citizenid VARCHAR(50) NOT NULL,
            rank_id INT DEFAULT NULL,
            joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY (citizenid),
            CONSTRAINT fk_member_company FOREIGN KEY (company_id) REFERENCES tycoon_companies(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Correção de esquema para Membros
    MySQL.query.await([[
        ALTER TABLE `tycoon_company_members` 
        ADD COLUMN IF NOT EXISTS `rank_id` INT DEFAULT NULL AFTER `citizenid`
    ]])
end)

-- ==========================================
-- GESTÃO DE EMPRESA (APLICATIVO TABLET)
-- ==========================================

lib.callback.register('cidade_tycoon_production:server:getCompanyDashboard', function(source)
    local p = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if not p then return nil end
    
    local citizenId = p.PlayerData.citizenid
    local company = MySQL.single.await([[
        SELECT c.*, 
        (SELECT COUNT(*) FROM tycoon_company_members WHERE company_id = c.id) as total_members
        FROM tycoon_companies c
        WHERE c.citizenid = ?
    ]], { citizenId })
    
    local role = 'owner'
    
    if not company then
        local member = MySQL.single.await('SELECT company_id FROM tycoon_company_members WHERE citizenid = ?', { citizenId })
        if member then
            company = MySQL.single.await('SELECT *, (SELECT COUNT(*) FROM tycoon_company_members WHERE company_id = tycoon_companies.id) as total_members FROM tycoon_companies WHERE id = ?', { member.company_id })
            role = 'member'
        end
    end

    if not company then return nil end

    local employees = MySQL.query.await([[
        SELECT m.citizenid, m.rank_id, r.name as rank_label
        FROM tycoon_company_members m
        LEFT JOIN tycoon_company_ranks r ON m.rank_id = r.id
        WHERE m.company_id = ?
    ]], { company.id })

    local ownerData = MySQL.single.await('SELECT citizenid FROM tycoon_companies WHERE id = ?', { company.id })

    return {
        company = company,
        role = role,
        employees = employees,
        ranks = MySQL.query.await('SELECT * FROM tycoon_company_ranks WHERE company_id = ?', { company.id }),
        stock = MySQL.query.await('SELECT item_key, amount FROM tycoon_warehouse_inventory WHERE company_id = ? AND amount > 0', { company.id })
    }
end)

RegisterNetEvent('cidade_tycoon_production:server:invitePlayer', function(targetId)
    local source = source
    local p = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    local target = exports.cidade_tycoon_core:GetFrameworkPlayer(tonumber(targetId))
    
    if not target then return TriggerClientEvent('ox_lib:notify', source, { title = 'Empresa', description = 'Cidadão não encontrado.', type = 'error' }) end
    
    local company = MySQL.single.await('SELECT id, name FROM tycoon_companies WHERE citizenid = ?', { p.PlayerData.citizenid })
    if not company then return end

    DebugLog("Convite enviado de %s para %s para a empresa %s", p.PlayerData.citizenid, target.PlayerData.citizenid, company.name)
    MySQL.insert.await('INSERT INTO tycoon_company_members (company_id, citizenid) VALUES (?, ?)', { company.id, target.PlayerData.citizenid })
    TriggerClientEvent('ox_lib:notify', target.PlayerData.source, { title = 'Emprego', description = 'Você foi contratado pela ' .. company.name, type = 'success' })
end)

-- ==========================================
-- PORTAL DE ENTRADA E PRODUÇÃO
-- ==========================================

lib.callback.register('cidade_tycoon_production:server:getEntranceData', function(source)
    local p = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if not p then return nil end
    local citizenId = p.PlayerData.citizenid
    local data = { companies = {}, isOwner = false }

    local ownerComp = MySQL.single.await('SELECT id, name FROM tycoon_companies WHERE citizenid = ?', { citizenId })
    if ownerComp then
        data.isOwner = true
        table.insert(data.companies, { id = ownerComp.id, name = ownerComp.name, role = 'owner' })
    end

    local memberComps = MySQL.query.await([[
        SELECT c.id, c.name, m.rank_id
        FROM tycoon_company_members m 
        JOIN tycoon_companies c ON m.company_id = c.id 
        WHERE m.citizenid = ?
    ]], { citizenId })
    
    if memberComps then
        for _, comp in ipairs(memberComps) do
            table.insert(data.companies, { id = comp.id, name = comp.name, role = 'Funcionário' })
        end
    end
    return data
end)

lib.callback.register('cidade_tycoon_production:server:createCompany', function(source)
    local p = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if not p then return { ok = false, message = "Erro ao identificar jogador." } end
    local citizenId = p.PlayerData.citizenid
    local exists = MySQL.single.await('SELECT id FROM tycoon_companies WHERE citizenid = ?', { citizenId })
    if exists then return { ok = false, message = "Você já possui uma empresa!" } end

    if exports.cidade_tycoon_core:RemoveMoney(source, 'bank', Config.CreationPrice, 'tycoon-company-registration') then
        local companyName = "Indústria de " .. p.PlayerData.charinfo.lastname
        local id = MySQL.insert.await([[INSERT INTO tycoon_companies (citizenid, name) VALUES (?, ?)]], { citizenId, companyName })
        return { ok = true, message = "Sua empresa '"..companyName.."' foi registrada!" }
    else
        return { ok = false, message = "Saldo insuficiente no banco!" }
    end
end)

-- Callbacks de Produção

lib.callback.register('cidade_tycoon_production:server:getCompanyLevel', function(source, companyId)
    if not companyId then return 1 end
    local comp = MySQL.single.await('SELECT level FROM tycoon_companies WHERE id = ?', { companyId })
    return comp and comp.level or 1
end)

lib.callback.register('cidade_tycoon_production:server:checkItems', function(source, requirements)
    local inv = exports.ox_inventory
    for _, req in ipairs(requirements) do
        local count = inv:Search(source, 'count', req.item)
        if count < req.count then return false end
    end
    return true
end)

RegisterNetEvent('cidade_tycoon_production:server:finishProduction', function(prodId, success)
    local source = source
    local prodData = Config.Products[prodId]
    if not prodData then return end
    
    local inv = exports.ox_inventory
    
    -- Revalidação de segurança no servidor
    for _, req in ipairs(prodData.requirements) do
        local count = inv:Search(source, 'count', req.item)
        if count < req.count then 
            DebugLog("Jogador %d tentou produzir sem itens suficientes. Possível exploit.", source)
            return 
        end
    end
    
    if success then
        for _, req in ipairs(prodData.requirements) do
            inv:RemoveItem(source, req.item, req.count)
        end
        
        -- Concede EXP à empresa e adiciona ao estoque do Galpão
        local p = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
        if p then
            local cid = p.PlayerData.citizenid
            local compId = nil
            local ownerComp = MySQL.single.await('SELECT id FROM tycoon_companies WHERE citizenid = ?', { cid })
            if ownerComp then 
                compId = ownerComp.id 
            else
                local memComp = MySQL.single.await('SELECT company_id FROM tycoon_company_members WHERE citizenid = ?', { cid })
                if memComp then compId = memComp.company_id end
            end
            
            if compId then
                -- Adiciona ao estoque do Galpão (Bulk Storage)
                MySQL.update.await([[
                    INSERT INTO tycoon_warehouse_inventory (company_id, item_key, amount)
                    VALUES (?, ?, 1)
                    ON DUPLICATE KEY UPDATE amount = amount + 1
                ]], { compId, prodId })

                MySQL.update.await('UPDATE tycoon_companies SET experience = experience + ? WHERE id = ?', { Config.ExperiencePerAction or 25, compId })
                
                -- Level Up Logic
                local company = MySQL.single.await('SELECT level, experience, name FROM tycoon_companies WHERE id = ?', { compId })
                if company then
                    local currentLevel = company.level
                    
                    -- Encontra o maior nível possível para o XP atual
                    local newLevel = currentLevel
                    for lvl, data in pairs(Config.Levels) do
                        if company.experience >= data.exp and lvl > newLevel then
                            newLevel = lvl
                        end
                    end
                    
                    if newLevel > currentLevel then
                        MySQL.update.await('UPDATE tycoon_companies SET level = ? WHERE id = ?', { newLevel, compId })
                        DebugLog("EMPRESA UP: %s subiu para o nível %d!", company.name, newLevel)
                        
                        -- Notifica todos os membros online
                        local members = MySQL.query.await('SELECT citizenid FROM tycoon_company_members WHERE company_id = ?', { compId })
                        local ownerCid = MySQL.single.await('SELECT citizenid FROM tycoon_companies WHERE id = ?', { compId })
                        
                        local toNotify = {}
                        if ownerCid then table.insert(toNotify, ownerCid.citizenid) end
                        if members then
                            for _, m in ipairs(members) do table.insert(toNotify, m.citizenid) end
                        end
                        
                        for _, targetCid in ipairs(toNotify) do
                            local target = exports.cidade_tycoon_core:GetPlayerFromCitizenId(targetCid)
                            if target then
                                TriggerClientEvent('ox_lib:notify', target.source, {
                                    title = 'Empresa Nível UP!',
                                    description = ('A %s agora é nível %d: %s'):format(company.name, newLevel, Config.Levels[newLevel].label),
                                    type = 'success',
                                    icon = 'industry'
                                })
                            end
                        end
                    end
                end
            end
        end
    else
        -- Falha: Remove metade dos materiais como penalidade
        for _, req in ipairs(prodData.requirements) do
            local penaltyAmount = math.max(1, math.floor(req.count / 2))
            inv:RemoveItem(source, req.item, penaltyAmount)
        end
    end
end)

-- ==========================================
-- GESTÃO DE ESTOQUE (WAREHOUSE INVENTORY)
-- ==========================================

lib.callback.register('cidade_tycoon_production:server:getWarehouseStock', function(source, companyId)
    if not companyId then return {} end
    return MySQL.query.await('SELECT item_key, amount FROM tycoon_warehouse_inventory WHERE company_id = ? AND amount > 0', { companyId })
end)

lib.callback.register('cidade_tycoon_production:server:withdrawItem', function(source, companyId, itemKey, amount)
    local p = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if not p or not companyId or not itemKey then return { ok = false, message = 'Dados inválidos.' } end
    amount = tonumber(amount) or 1

    -- Verifica se tem no estoque
    local row = MySQL.single.await('SELECT amount FROM tycoon_warehouse_inventory WHERE company_id = ? AND item_key = ?', { companyId, itemKey })
    if not row or row.amount < amount then
        return { ok = false, message = 'Estoque insuficiente no galpão.' }
    end

    -- Remove do galpão e dá ao jogador
    local success = MySQL.update.await('UPDATE tycoon_warehouse_inventory SET amount = amount - ? WHERE company_id = ? AND item_key = ?', { amount, companyId, itemKey })
    if success then
        exports.ox_inventory:AddItem(source, itemKey, amount)
        return { ok = true, message = ('Retirado %dx %s do estoque.'):format(amount, itemKey) }
    end

    return { ok = false, message = 'Falha ao processar retirada.' }
end)

RegisterNetEvent('cidade_tycoon_production:server:enterWarehouse', function(companyId)
    local source = source
    if not companyId then return end
    setPlayerToCompanyBucket(source, companyId)
end)

RegisterNetEvent('cidade_tycoon_production:server:leaveWarehouse', function()
    local source = source
    resetPlayerBucket(source)
end)

AddEventHandler('playerDropped', function()
    local source = source
    if activeBuckets[source] then resetPlayerBucket(source) end
end)

-- ==========================================
-- EXPORTS
-- ==========================================

exports('GetPlayerCompany', function(source)
    local p = exports.cidade_tycoon_core:GetFrameworkPlayer(source)
    if not p then return nil end
    local company = MySQL.single.await('SELECT * FROM tycoon_companies WHERE citizenid = ?', { p.PlayerData.citizenid })
    if company then return company, 'owner' end
    local member = MySQL.single.await('SELECT company_id, rank_name FROM tycoon_company_members WHERE citizenid = ?', { p.PlayerData.citizenid })
    if member then
        local comp = MySQL.single.await('SELECT * FROM tycoon_companies WHERE id = ?', { member.company_id })
        return comp, member.rank_name
    end
    return nil
end)
