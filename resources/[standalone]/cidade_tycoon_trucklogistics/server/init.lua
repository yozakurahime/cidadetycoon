CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `trucker_available_contracts` (
            `contract_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
            `contract_type` TINYINT(1) NOT NULL DEFAULT 0,
            `contract_name` varchar(50) NOT NULL DEFAULT '',
            `coords_index` smallint(6) unsigned NOT NULL DEFAULT 0,
            `price_per_km` BIGINT unsigned NOT NULL DEFAULT 0,
            `cargo_type` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `fragile` TINYINT(1) NOT NULL DEFAULT 0,
            `valuable` TINYINT(1) NOT NULL DEFAULT 0,
            `fast` TINYINT(1) NOT NULL DEFAULT 0,
            `truck` varchar(50) DEFAULT NULL,
            `trailer` varchar(50) NOT NULL,
            PRIMARY KEY (`contract_id`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `trucker_drivers` (
            `driver_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
            `user_id` varchar(50) DEFAULT NULL,
            `name` varchar(50) NOT NULL DEFAULT '',
            `product_type` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `distance` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `valuable` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `fragile` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `fast` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `price` BIGINT unsigned NOT NULL DEFAULT 0,
            `price_per_km` BIGINT unsigned NOT NULL DEFAULT 0,
            `img` varchar(255) DEFAULT NULL,
            PRIMARY KEY (`driver_id`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `trucker_loans` (
            `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
            `user_id` varchar(50) NOT NULL,
            `loan` BIGINT unsigned NOT NULL DEFAULT 0,
            `remaining_amount` BIGINT unsigned NOT NULL DEFAULT 0,
            `day_cost` BIGINT unsigned NOT NULL DEFAULT 0,
            `taxes_on_day` BIGINT unsigned NOT NULL DEFAULT 0,
            `timer` int(10) unsigned NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `trucker_trucks` (
            `truck_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
            `user_id` varchar(50) NOT NULL,
            `truck_name` varchar(50) NOT NULL,
            `driver` int(10) unsigned DEFAULT NULL,
            `body` smallint(5) unsigned NOT NULL DEFAULT 1000,
            `engine` smallint(5) unsigned NOT NULL DEFAULT 1000,
            `transmission` smallint(5) unsigned NOT NULL DEFAULT 1000,
            `wheels` smallint(5) unsigned NOT NULL DEFAULT 1000,
            PRIMARY KEY (`truck_id`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `trucker_users` (
            `user_id` varchar(50) NOT NULL,
            `money` BIGINT unsigned NOT NULL DEFAULT 0,
            `total_earned` BIGINT unsigned NOT NULL DEFAULT 0,
            `finished_deliveries` int(10) unsigned NOT NULL DEFAULT 0,
            `exp` int(10) unsigned NOT NULL DEFAULT 0,
            `traveled_distance` double unsigned NOT NULL DEFAULT 0,
            `skill_points` int(10) unsigned NOT NULL DEFAULT 0,
            `product_type` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `distance` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `valuable` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `fragile` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `fast` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `loan_notify` TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`user_id`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `trucker_offline_notifications` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `user_id` VARCHAR(50) NOT NULL,
            `message` TEXT NOT NULL,
            `notification_type` VARCHAR(50) NOT NULL DEFAULT 'success',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Clean up legacy remote bootdey avatar URLs to point to local assets
    MySQL.query.await([[
        UPDATE trucker_drivers 
        SET img = REPLACE(img, 'https://bootdey.com/img/Content/avatar/', 'img/')
        WHERE img LIKE 'https://bootdey.com/img/Content/avatar/%'
    ]])

    -- Deleta motoristas da agência não contratados para forçar a geração com os novos nomes corretos do Config
    MySQL.query.await("DELETE FROM trucker_drivers WHERE user_id IS NULL")

    -- Migração para novos campos de status e financeiro
    MySQL.query.await([[
        ALTER TABLE `trucker_drivers` 
        ADD COLUMN IF NOT EXISTS `status` VARCHAR(50) DEFAULT 'IDLE',
        ADD COLUMN IF NOT EXISTS `current_job_reward` BIGINT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS `current_cargo_name` VARCHAR(100) DEFAULT NULL,
        ADD COLUMN IF NOT EXISTS `active_event` VARCHAR(100) DEFAULT NULL,
        ADD COLUMN IF NOT EXISTS `route_events` LONGTEXT DEFAULT NULL,
        ADD COLUMN IF NOT EXISTS `pending_event_data` LONGTEXT DEFAULT NULL,
        ADD COLUMN IF NOT EXISTS `total_profit` BIGINT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS `total_spent` BIGINT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS `timer` INT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS `level` INT DEFAULT 1,
        ADD COLUMN IF NOT EXISTS `exp` INT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS `finished_deliveries` INT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS `traveled_distance` DOUBLE DEFAULT 0,
        ADD COLUMN IF NOT EXISTS `total_work_time` BIGINT DEFAULT 0
    ]])

    -- Migração para novo sistema de combustível e comboio cooperativo
    MySQL.query.await([[
        ALTER TABLE `trucker_users` 
        ADD COLUMN IF NOT EXISTS `fuel_stock` INT UNSIGNED DEFAULT 0
    ]])
    -- Fix existing users with NULL fuel_stock
    MySQL.update.await([[
        UPDATE `trucker_users` SET `fuel_stock` = 0 WHERE `fuel_stock` IS NULL
    ]])
    MySQL.query.await([[
        ALTER TABLE `trucker_available_contracts` 
        ADD COLUMN IF NOT EXISTS `coop` TINYINT(1) DEFAULT 0
    ]])
end)
