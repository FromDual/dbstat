-- Show everything we tracked from a specific connection which was not sleeping

SELECT DISTINCT connection_id, user, host FROM processlist;

SELECT connection_id, ts, command, time, state, SUBSTR(REGEXP_REPLACE(REPLACE(query, "\n", ' '), '\ +', ' '), 1, 64)
  FROM processlist
 WHERE command != 'Sleep'
   AND connection_id = 4327
 ORDER BY ts ASC
;
