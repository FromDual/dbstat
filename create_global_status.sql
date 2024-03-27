CREATE TABLE IF NOT EXISTS `global_status` (
  `machine_name` VARCHAR (255) NOT NULL
, `variable_name` VARCHAR(64) NOT NULL
, `ts` TIMESTAMP NOT NULL
, `variable_value` VARCHAR(4096) NOT NULL
, PRIMARY KEY (`machine_name`, `variable_name`, `ts`)
, INDEX (`ts`)
);
-- Index for the lazy ones omitting the machine_name
ALTER TABLE `global_status` ADD INDEX (`variable_name`);

DELIMITER //

-- We gather about 500 - 600 rows per minute, around 1 Mio rows/day, 30 Mio rows/month
CREATE OR REPLACE DEFINER = `dbstat`@`localhost` EVENT gather_global_status
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
  INSERT INTO `global_status`
  SELECT @@hostname, LOWER(variable_name) AS variable_name, CURRENT_TIMESTAMP(), variable_value
    FROM information_schema.global_status
  ;
END;
//

DELIMITER ;

DELIMITER //

-- We keep global_status for 30 days
CREATE OR REPLACE DEFINER = `dbstat`@`localhost` EVENT purge_global_status
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
  DELETE FROM `global_status`
   WHERE machine_name = @@hostname
     AND `ts` < DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
   LIMIT 1000
  ;
END;
//

DELIMITER ;

-- If events should also run on Slave they must be enabled separately:
-- SET SESSION sql_log_bin = off;
-- ALTER EVENT `gather_global_status` ENABLE;
-- ALTER EVENT `purge_global_status` ENABLE;
