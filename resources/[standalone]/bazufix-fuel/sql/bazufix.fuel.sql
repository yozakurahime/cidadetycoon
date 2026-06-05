CREATE TABLE IF NOT EXISTS `bazufix_fuel_stations` (
    `id`            INT          NOT NULL,
    `name`          VARCHAR(100) NOT NULL,
    `owner_id`      VARCHAR(60)  DEFAULT NULL,
    `owner_name`    VARCHAR(80)  DEFAULT NULL,
    `price_eco`     INT          NOT NULL DEFAULT 8,
    `price_normal`  INT          NOT NULL DEFAULT 12,
    `price_super`   INT          NOT NULL DEFAULT 18,
    `price_elec`    INT          NOT NULL DEFAULT 6,
    `total_income`  BIGINT       NOT NULL DEFAULT 0,
    `buy_price`     INT          NOT NULL DEFAULT 150000,
    `safe_balance`  BIGINT       NOT NULL DEFAULT 0,
    `stock`         INT          DEFAULT NULL COMMENT 'NULL = unlimited (unowned)',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `bazufix_fuel_stations` ADD COLUMN IF NOT EXISTS `safe_balance` BIGINT NOT NULL DEFAULT 0;
ALTER TABLE `bazufix_fuel_stations` ADD COLUMN IF NOT EXISTS `stock` INT DEFAULT NULL;