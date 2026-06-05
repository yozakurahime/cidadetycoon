CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `trucker_available_contracts` (
            `contract_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
            `contract_type` bit(1) NOT NULL DEFAULT b'0',
            `contract_name` varchar(50) NOT NULL DEFAULT '',
            `coords_index` smallint(6) unsigned NOT NULL DEFAULT 0,
            `price_per_km` int(10) unsigned NOT NULL DEFAULT 0,
            `cargo_type` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `fragile` bit(1) NOT NULL DEFAULT b'0',
            `valuable` bit(1) NOT NULL DEFAULT b'0',
            `fast` bit(1) NOT NULL DEFAULT b'0',
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
            `price` int(10) unsigned NOT NULL DEFAULT 0,
            `price_per_km` int(10) unsigned NOT NULL DEFAULT 0,
            `img` varchar(255) DEFAULT NULL,
            PRIMARY KEY (`driver_id`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `trucker_loans` (
            `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
            `user_id` varchar(50) NOT NULL,
            `loan` int(10) unsigned NOT NULL DEFAULT 0,
            `remaining_amount` int(10) unsigned NOT NULL DEFAULT 0,
            `day_cost` int(10) unsigned NOT NULL DEFAULT 0,
            `taxes_on_day` int(10) unsigned NOT NULL DEFAULT 0,
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
            `money` int(10) unsigned NOT NULL DEFAULT 0,
            `total_earned` int(10) unsigned NOT NULL DEFAULT 0,
            `finished_deliveries` int(10) unsigned NOT NULL DEFAULT 0,
            `exp` int(10) unsigned NOT NULL DEFAULT 0,
            `traveled_distance` double unsigned NOT NULL DEFAULT 0,
            `skill_points` int(10) unsigned NOT NULL DEFAULT 0,
            `product_type` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `distance` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `valuable` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `fragile` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `fast` tinyint(3) unsigned NOT NULL DEFAULT 0,
            `loan_notify` bit(1) NOT NULL DEFAULT b'0',
            PRIMARY KEY (`user_id`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)
