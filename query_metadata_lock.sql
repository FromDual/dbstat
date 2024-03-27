SET @machine_name = @@hostname;

-- Connections, having metadata locks in the last day:
SELECT connection_id, ts, user, host, table_schema, table_name, state, SUBSTR(REGEXP_REPLACE(REPLACE(query, "\n", ' '), '\ +', ' '), 1, 64)
  FROM metadata_lock
 WHERE machine_name = @machine_name
   AND ts >= DATE_SUB(NOW(), INTERVAL 1 DAY)
 ORDER BY ts ASC
;
