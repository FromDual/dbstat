CREATE TABLE IF NOT EXISTS `trx_and_lck` (
  `connection_id` BIGINT NOT NULL
, `trx_id` BIGINT UNSIGNED NOT NULL
, `ts` TIMESTAMP NOT NULL
, `user` VARCHAR(128) NOT NULL
, `host` VARCHAR(64) NOT NULL
, `db` VARCHAR(64)
, `command` VARCHAR(16) NOT NULL
, `time` DECIMAL(22, 3) NOT NULL
, `running_since` DATETIME NOT NULL
, `state` VARCHAR(64)
, `info` LONGTEXT
, `trx_state` VARCHAR(13) NOT NULL
, `trx_started` DATETIME NOT NULL
, `trx_requested_lock_id` VARCHAR(81)
, `trx_tables_in_use` BIGINT UNSIGNED NOT NULL
, `trx_tables_locked` BIGINT UNSIGNED NOT NULL
, `trx_lock_structs` BIGINT UNSIGNED NOT NULL
, `trx_rows_locked` BIGINT UNSIGNED NOT NULL
, `trx_rows_modified` BIGINT UNSIGNED NOT NULL
, `lock_mode` ENUM('S','S,GAP','X','X,GAP','IS','IS,GAP','IX','IX,GAP','AUTO_INC') NOT NULL
, `lock_type` ENUM('RECORD','TABLE') NOT NULL
, `lock_table_schema` VARCHAR(64) NOT NULL
, `lock_table_name` VARCHAR(64) NOT NULL
, `lock_index` VARCHAR(1024) NOT NULL
, `lock_space` INT UNSIGNED
, `lock_page` INT UNSIGNED 
, `lock_rec` INT UNSIGNED 
, `lock_data` VARCHAR(8192)
, PRIMARY KEY (`connection_id`, `trx_id`, `ts`)
);
ALTER TABLE `trx_and_lck` ADD INDEX (`ts`);
-- TODO: Which indexes are missing

DELIMITER //

-- If we have 1000 connections we generate about 1 Mio rows per day
CREATE OR REPLACE DEFINER = `dbstat`@`localhost` EVENT gather_trx_and_lck
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
  INSERT INTO `trx_and_lck`
  SELECT pl.id, trx.trx_id, CURRENT_TIMESTAMP()
       , pl.user, pl.host, pl.db , pl.command, pl.time, FROM_UNIXTIME(UNIX_TIMESTAMP()-pl.time)
       , pl.state, IFNULL(pl.info, '')
       , trx.trx_state, trx.trx_started, trx.trx_requested_lock_id
       , trx.trx_tables_in_use, trx.trx_tables_locked, trx.trx_lock_structs, trx.trx_rows_locked, trx.trx_rows_modified
       , lck.lock_mode, lck.lock_type
       , TRIM(BOTH '`' FROM SUBSTR(lck.lock_table, 1, INSTR(lck.lock_table, '.')-1))
       , TRIM(BOTH '`' FROM SUBSTR(lck.lock_table, INSTR(lck.lock_table, '.')+1))
       , lck.lock_index, lck.lock_space, lck.lock_page, lck.lock_rec, lck.lock_data
    FROM information_schema.innodb_trx AS trx
    JOIN information_schema.processlist AS pl ON pl.id = trx.trx_mysql_thread_id
    JOIN information_schema.innodb_locks AS lck ON trx.trx_id = lck.lock_trx_id
  ;
END;
//

DELIMITER ;

DELIMITER //

-- We keep trx_and_lck for 7 days
CREATE OR REPLACE DEFINER = `dbstat`@`localhost` EVENT purge_trx_and_lck
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
  DELETE FROM `trx_and_lck`
   WHERE `ts` < DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
   LIMIT 1000
  ;
END;
//

DELIMITER ;

-- Queries

