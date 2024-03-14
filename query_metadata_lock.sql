-- Connections, having metadata locks in the last day:

SELECT connection_id, ts, user, host, table_schema, table_name, state, SUBSTR(REGEXP_REPLACE(REPLACE(query, "\n", ' '), '\ +', ' '), 1, 64)
  FROM metadata_lock
 WHERE ts >= DATE_SUB(NOW(), INTERVAL 1 DAY)
 ORDER BY ts ASC
;
