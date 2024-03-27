CREATE TABLE IF NOT EXISTS `processlist` (
  `connection_id` BIGINT NOT NULL
, `ts` TIMESTAMP NOT NULL
, `user` VARCHAR(128) NOT NULL
, `host` VARCHAR(64) NOT NULL
, `db` VARCHAR(64)
, `command` VARCHAR(16) NOT NULL
, `time` DECIMAL(22, 3) NOT NULL
, `state` VARCHAR(64)
, `query` LONGTEXT
, `stage` TINYINT NOT NULL
, `max_stage` TINYINT NOT NULL
, `progress` DECIMAL(7, 3) NOT NULL
, `memory_used` BIGINT NOT NULL
, `max_memory_used` BIGINT NOT NULL
, `examined_rows` INT NOT NULL
, PRIMARY KEY (`connection_id`, `ts`)
);
ALTER TABLE `processlist` ADD INDEX (`ts`);
-- TODO: Which indexes are missing
-- RFC 1123
ALTER TABLE `processlist`
  ADD COLUMN `machine_name` VARCHAR (255) NOT NULL FIRST
, DROP PRIMARY KEY
, ADD PRIMARY KEY (`machine_name`, `connection_id`, `ts`)
;

DELIMITER //

-- If we have 1000 connections we generate about 1 Mio rows per day
CREATE OR REPLACE DEFINER = `dbstat`@`localhost` EVENT gather_processlist
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
  INSERT INTO `processlist`
  SELECT @@hostname, id, CURRENT_TIMESTAMP(), user, host, db, command, ROUND(time_ms/1000, 3), state, info
       , stage, max_stage, progress, memory_used, max_memory_used, examined_rows
    FROM information_schema.processlist
   WHERE id != CONNECTION_ID()
  ;
END;
//

DELIMITER ;

DELIMITER //

-- We keep processlist for 7 days
CREATE OR REPLACE DEFINER = `dbstat`@`localhost` EVENT purge_processlist
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
  DELETE FROM `processlist`
   WHERE machine_name = @@hostname
     AND `ts` < DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
   LIMIT 1000
  ;
END;
//

DELIMITER ;

-- If events should also run on Slave they must be enabled separately:
-- SET SESSION sql_log_bin = off;
-- ALTER EVENT `gather_processlist` ENABLE;
-- ALTER EVENT `purge_processlist` ENABLE;
