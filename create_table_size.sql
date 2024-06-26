CREATE TABLE IF NOT EXISTS `table_size` (
-- RFC 1123
  `machine_name` VARCHAR (255) NOT NULL
, `table_catalog` VARCHAR(512) NOT NULL
, `table_schema` VARCHAR(64) NOT NULL
, `table_name` VARCHAR(64) NOT NULL
, `ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
, `engine` VARCHAR(64) NOT NULL
, `table_rows` BIGINT UNSIGNED
, `data_length` BIGINT UNSIGNED
, `index_length` BIGINT UNSIGNED
, `data_free` BIGINT UNSIGNED
, PRIMARY KEY (`machine_name`, `table_catalog`, `table_schema`, `table_name`, `ts`)
-- For delete job
, INDEX (`ts`)
);

DELIMITER //

-- We collect table size once a day during night
-- Reschedule if this is you prime time
-- or change frequence if needed
CREATE OR REPLACE DEFINER = `dbstat`@`localhost` EVENT gather_table_size
ON SCHEDULE EVERY 1 DAY
STARTS CONCAT(CURRENT_DATE(), ' 02:04:00')
/*!110502 ENABLE ON SLAVE */
DO
BEGIN
  -- takes about 0.5s for 1000 tables
  INSERT INTO `table_size`
  SELECT @@hostname, table_catalog, table_schema, table_name, CURRENT_TIMESTAMP(), engine, table_rows, data_length, index_length,  data_free
    FROM information_schema.tables
   WHERE table_type = 'BASE TABLE'
     AND table_schema NOT IN ('mysql', 'information_schema', 'sys', 'performance_schema')
  ;
END;
//

DELIMITER ;

DELIMITER //

-- Should also work with a big amount of tables (288k tables/d)
-- Adapt values (5 MINUTE (smaller) / LIMIT 1000 (higher)) if you have more tables!
CREATE OR REPLACE DEFINER = `dbstat`@`localhost` EVENT purge_table_size
ON SCHEDULE EVERY 5 MINUTE
/*!110502 ENABLE ON SLAVE */
DO
BEGIN
  DELETE FROM `table_size`
   WHERE machine_name = @@hostname
     AND `ts` < DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 31 DAY)
   LIMIT 1000
  ;
END;
//

DELIMITER ;

-- If events should also run on Slave they must be enabled separately:
-- SET SESSION sql_log_bin = off;
-- ALTER EVENT `gather_table_size` ENABLE;
-- ALTER EVENT `purge_table_size` ENABLE;
