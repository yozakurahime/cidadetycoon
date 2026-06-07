local function setupLogisticsDatabase()
    -- Main Companies Table
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_companies (
            id INT NOT NULL AUTO_INCREMENT,
            citizenid VARCHAR(50) NOT NULL,
            name VARCHAR(80) NOT NULL DEFAULT 'Nova Empresa Logística',
            level INT DEFAULT 1,
            experience INT DEFAULT 0,
            vault_balance BIGINT NOT NULL DEFAULT 0,
            warehouse_id INT DEFAULT NULL,
            upgrades LONGTEXT DEFAULT NULL,
            is_active TINYINT(1) DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY (citizenid)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Fleet Table (Linking vehicles to companies)
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_company_fleet (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            vehicle_plate VARCHAR(15) NOT NULL,
            assigned_npc_id INT DEFAULT NULL,
            status VARCHAR(20) DEFAULT 'idle', -- 'idle', 'active', 'maintenance'
            PRIMARY KEY (id),
            UNIQUE KEY (vehicle_plate),
            INDEX (company_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- NPC Employees Table
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_company_employees (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            name VARCHAR(50) NOT NULL,
            skill_level INT DEFAULT 1,
            salary INT DEFAULT 500,
            status VARCHAR(20) DEFAULT 'available', -- 'available', 'working', 'off'
            PRIMARY KEY (id),
            INDEX (company_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- NPC Active Deliveries (For virtualization tracking)
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_npc_deliveries (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            employee_id INT NOT NULL,
            vehicle_plate VARCHAR(15) NOT NULL,
            route_data LONGTEXT NOT NULL,
            progress FLOAT DEFAULT 0.0,
            start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            eta TIMESTAMP NULL DEFAULT NULL,
            status VARCHAR(20) DEFAULT 'in_progress', -- 'in_progress', 'completed', 'failed'
            PRIMARY KEY (id),
            INDEX (company_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Job Board for Freelancers
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_job_board (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            title VARCHAR(100) NOT NULL,
            reward BIGINT NOT NULL DEFAULT 0,
            cargo_type VARCHAR(50) NOT NULL,
            origin_coords LONGTEXT NOT NULL,
            dest_coords LONGTEXT NOT NULL,
            status VARCHAR(20) DEFAULT 'posted', -- 'posted', 'taken', 'completed'
            assigned_citizenid VARCHAR(50) DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            INDEX (company_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    print("^2[Tycoon:Logistics]^7 Banco de dados de logística inicializado com sucesso.")
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    setupLogisticsDatabase()
end)
