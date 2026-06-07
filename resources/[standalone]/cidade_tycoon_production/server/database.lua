local function setupProductionDatabase()
    -- Production Lines
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_production_lines (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            recipe_key VARCHAR(50) NOT NULL,
            start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            end_time TIMESTAMP NULL DEFAULT NULL,
            status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed'
            PRIMARY KEY (id),
            INDEX (company_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Company Warehouse Inventory (Bulk materials)
    MySQL.update.await([[
        CREATE TABLE IF NOT EXISTS tycoon_warehouse_inventory (
            id INT NOT NULL AUTO_INCREMENT,
            company_id INT NOT NULL,
            item_key VARCHAR(50) NOT NULL,
            amount BIGINT DEFAULT 0,
            PRIMARY KEY (id),
            UNIQUE KEY uniq_warehouse_item (company_id, item_key),
            INDEX (company_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    print("^2[Tycoon:Production]^7 Banco de dados de produção inicializado com sucesso.")
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    setupProductionDatabase()
end)
