-- Get locks in the last day
SELECT connection_id, trx_id, ts, user, host, db, command, time, running_since, state
     , SUBSTR(REGEXP_REPLACE(REPLACE(query, "\n", ' '), '\ +', ' '), 1, 64) AS query
     , trx_state, trx_started, trx_requested_lock_id, trx_tables_in_use, trx_tables_locked, trx_lock_structs, trx_rows_locked, trx_rows_modified
     , lock_mode, lock_type, lock_table_schema, lock_table_name, lock_index, lock_space, lock_page, lock_rec, lock_data
  FROM trx_and_lck
 WHERE ts > DATE_SUB(NOW(), INTERVAL 1 DAY)
 ORDER BY ts ASC
;
