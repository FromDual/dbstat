-- The metadata lock info plugin must be installed first:
-- https://mariadb.com/kb/en/metadata-lock-info-plugin/
--
-- SQL> SELECT plugin_name, plugin_status, plugin_author, plugin_description, load_option, plugin_maturity
--   FROM information_schema.plugins
--  WHERE plugin_name = 'METADATA_LOCK_INFO'
-- ;
-- +--------------------+---------------+---------------+-------------------------+-------------+-----------------+
-- | plugin_name        | plugin_status | plugin_author | plugin_description      | load_option | plugin_maturity |
-- +--------------------+---------------+---------------+-------------------------+-------------+-----------------+
-- | METADATA_LOCK_INFO | ACTIVE        | Kentoku Shiba | Metadata locking viewer | ON          | Stable          |
-- +--------------------+---------------+---------------+-------------------------+-------------+-----------------+
--
-- SQL> INSTALL SONAME 'metadata_lock_info';
--

CREATE TABLE IF NOT EXISTS `metadata_lock` (
  `connection_id` BIGINT NOT NULL
, `lock_mode` VARCHAR(24)
, `ts` TIMESTAMP NOT NULL
, `user` VARCHAR(128) NOT NULL
, `host` VARCHAR(64) NOT NULL
, `lock_type` VARCHAR(33)
, `table_schema` VARCHAR(64)
, `table_name` VARCHAR(64)
, `lock_duration` VARCHAR(30)
, `db` VARCHAR(64)
, `time` DECIMAL(22, 3) NOT NULL
, `started` DATETIME NOT NULL
, `command` VARCHAR(16) NOT NULL
, `state` VARCHAR(64)
, `query` LONGTEXT
-- Not sure if this PK is unique?
, PRIMARY KEY (`connection_id`, `lock_mode`, `ts`)
);
ALTER TABLE `metadata_lock` ADD INDEX (`ts`);
-- TODO: Which indexes are missing
-- RFC 1123
ALTER TABLE `metadata_lock`
  ADD COLUMN `machine_name` VARCHAR (255) NOT NULL FIRST
, DROP PRIMARY KEY
, ADD PRIMARY KEY (`machine_name`, `connection_id`, `lock_mode`, `ts`)
;
ALTER TABLE `metadata_lock`
  ADD COLUMN `aiid` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT AFTER `ts`
, ADD UNIQUE INDEX (aiid)
;

DELIMITER //

-- If we have 1000 connections we generate about 1 Mio rows per day
CREATE OR REPLACE DEFINER = `dbstat`@`localhost` EVENT gather_metadata_lock
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
  INSERT INTO `metadata_lock`
  SELECT @@hostname, mdl.thread_id, mdl.lock_mode, CURRENT_TIMESTAMP(), NULL, pl.user, pl.host, mdl.lock_type, mdl.table_schema, mdl.table_name, mdl.lock_duration
       , pl.db AS actual_schema, pl.time, DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL time SECOND) AS startet, pl.command, pl.state, pl.info AS query
    FROM information_schema.metadata_lock_info AS mdl
    JOIN information_schema.processlist AS pl ON pl.id = mdl.thread_id
   WHERE pl.id != CONNECTION_ID()
  ;
END;
//

DELIMITER ;

DELIMITER //

-- We keep metadata_lock for 7 days
CREATE OR REPLACE DEFINER = `dbstat`@`localhost` EVENT purge_metadata_lock
ON SCHEDULE EVERY 5 MINUTE
DO
BEGIN
  DELETE FROM `metadata_lock`
   WHERE machine_name = @@hostname
     AND `ts` < DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
   LIMIT 1000
  ;
END;
//

DELIMITER ;

-- If events should also run on Slave they must be enabled separately:
-- SET SESSION sql_log_bin = off;
-- ALTER EVENT `gather_metadata_lock` ENABLE;
-- ALTER EVENT `purge_metadata_lock` ENABLE;
