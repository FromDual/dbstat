-- Connections, having metadata locks:

SELECT connection_id, ts, user, host, table_schema, table_name, state, SUBSTR(REGEXP_REPLACE(REPLACE(query, "\n", ' '), '\ +', ' '), 1, 64)
  FROM metadata_lock
 ORDER BY ts ASC
;
