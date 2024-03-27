SET @machine_name = @@hostname;

-- Show everything we tracked from a specific connection which was not sleeping
SELECT connection_id, user, host, COUNT(*)
  FROM processlist
 WHERE machine_name = @machine_name
   AND command != 'Sleep'
   AND state NOT IN (
       'Waiting for next activation'
     , 'Master has sent all binlog to slave; waiting for more updates'
     , 'Waiting for master to send event'
     , 'Slave has read all relay log; waiting for more updates'
       )
 GROUP BY connection_id, user, host
 HAVING COUNT(*) > 1
;

SET @connection_id = <value from query above>;

SELECT connection_id, ts, command, time, state, SUBSTR(REGEXP_REPLACE(REPLACE(query, "\n", ' '), '\ +', ' '), 1, 64)
  FROM processlist
 WHERE machine_name = @machine_name
   AND command != 'Sleep'
   AND connection_id = @connection_id
   AND state NOT IN (
       'Waiting for next activation'
     , 'Master has sent all binlog to slave; waiting for more updates'
     , 'Waiting for master to send event'
     , 'Slave has read all relay log; waiting for more updates'
       )
 ORDER BY ts ASC
;
