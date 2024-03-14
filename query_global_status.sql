-- Select time series of one specific status
SELECT ts, variable_value AS 'threads_running'
  FROM global_status
 WHERE variable_name = 'threads_running'
 ORDER BY ts ASC
;

-- Select time series of two specific status'
SELECT s1.ts
     , s1.variable_value AS 'table_open_cache_misses'
     , s2.variable_value AS 'table_open_cache_hits'
  FROM global_status AS s1
  JOIN global_status AS s2 ON s1.ts = s2.ts
 WHERE s1.variable_name = 'table_open_cache_misses'
   AND s2.variable_name = 'table_open_cache_hits'
 ORDER BY ts ASC
;

-- Delta to previous value
SELECT ts, variable_value
     , variable_value - LAG(variable_value)
  OVER (ORDER BY variable_value) AS difference_to_previous
  FROM global_status
 WHERE variable_name = 'table_open_cache_misses'
 ORDER BY ts ASC
;

-- Select time series of two specific status' and create .csv file for later import into Excel
SELECT s1.ts
     , s1.variable_value AS 'innodb_rows_deleted'
     , s2.variable_value AS 'innodb_rows_inserted'
  INTO OUTFILE '/tmp/innodb_rows.csv'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
 LINES TERMINATED BY '\n'
  FROM global_status AS s1
  JOIN global_status AS s2 ON s1.ts = s2.ts
 WHERE s1.variable_name = 'innodb_rows_deleted'
   AND s2.variable_name = 'innodb_rows_inserted'
 ORDER BY ts ASC
;

-- Select time series of two specific status' and create .csv file for gnuplot
SELECT UNIX_TIMESTAMP(s1.ts)
     , s1.variable_value AS 'innodb_rows_deleted'
     , s2.variable_value AS 'innodb_rows_inserted'
  INTO OUTFILE '/tmp/innodb_rows.csv'
FIELDS TERMINATED BY "\t"
 LINES TERMINATED BY '\n'
  FROM global_status AS s1
  JOIN global_status AS s2 ON s1.ts = s2.ts
 WHERE s1.variable_name = 'innodb_rows_deleted'
   AND s2.variable_name = 'innodb_rows_inserted'
 ORDER BY s1.ts ASC
;

-- gnuplot> plot "/tmp/innodb_rows.csv" using 1:2 title 'rows_deleted' with lines, \
--               "/tmp/innodb_rows.csv" using 1:3 title 'rows inserted' with lines

-- Min/max/avg per hour of a specific status
SELECT SUBSTR(ts, 1, 13) AS per_hour
     , MIN(variable_value) AS 'threads_running_min'
     , MAX(variable_value) AS 'threads_running_max'
     , ROUND(AVG(variable_value), 1) AS 'threads_running_avg'
  FROM global_status
 WHERE variable_name = 'threads_running'
 GROUP BY SUBSTR(ts, 1, 13)
 ORDER BY ts ASC
;
