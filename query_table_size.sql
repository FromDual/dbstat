SET @machine_name = @@hostname;

-- Rows for one table
SELECT `table_catalog`, `table_schema`, `table_name`, `ts`, `table_rows`
  FROM `table_size`
 WHERE `machine_name` = @machine_name
   AND `table_catalog` = 'def'
   AND `table_schema` = 'dbstat'
   AND `table_name` = 'table_size'
 ORDER BY `ts` ASC
;

-- Data per schema per catalog for one schema
SELECT `table_catalog`, `table_schema`, `ts`
     , SUM(`data_length`) AS data_length, SUM(`index_length`) AS index_length, SUM(`data_free`) AS data_free
  FROM `table_size`
 WHERE `machine_name` = @machine_name
   AND `table_catalog` = 'def'
   AND `table_schema` = 'dbstat'
 GROUP BY `table_catalog`, `table_schema`, `ts`
 ORDER BY `table_catalog`, `table_schema`, `ts` ASC
;

-- Data per catalog
SELECT `table_catalog`, `ts`
     , SUM(`data_length`) AS data_length, SUM(`index_length`) AS index_length, SUM(`data_free`) AS data_free
  FROM `table_size`
 WHERE `machine_name` = @machine_name
   AND `table_catalog` = 'def'
 GROUP BY `table_catalog`, `ts`
 ORDER BY `table_catalog`, `ts` ASC
;

-- Data per Storage Engine
SELECT `engine`, `ts`
     , SUM(`data_length`) AS data_length, SUM(`index_length`) AS index_length, SUM(`data_free`) AS data_free
  FROM `table_size`
 WHERE `machine_name` = @machine_name
 GROUP BY `engine`, `ts`
 ORDER BY `engine`, `ts` ASC
;
