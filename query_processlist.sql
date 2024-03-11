-- Show everything we tracked from a specific connection which was not sleeping

SELECT connection_id, user, host, COUNT(*) FROM processlist GROUP BY connection_id, user, host;

SET @connection_id = 14973;

SELECT connection_id, ts, command, time, state, SUBSTR(REGEXP_REPLACE(REPLACE(query, "\n", ' '), '\ +', ' '), 1, 64)
  FROM processlist
 WHERE command != 'Sleep'
   AND connection_id = @connection_id
 ORDER BY ts ASC
;
