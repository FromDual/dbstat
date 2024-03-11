CREATE TABLE IF NOT EXISTS `global_status` (
  `machine_name` VARCHAR (255) NOT NULL
, `variable_name` VARCHAR(64) NOT NULL
, `ts` TIMESTAMP NOT NULL
, `variable_value` VARCHAR(4096) NOT NULL
, PRIMARY KEY (`machine_name`, `variable_name`, `ts`)
, INDEX (`ts`)
);

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
   WHERE `ts` < DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
   LIMIT 1000
  ;
END;
//

DELIMITER ;
