SET @machine_name = @@hostname;

-- Show all variables which have changed:
SELECT variable_name, ts, variable_value
  FROM global_variables
 WHERE machine_name = @machine_name
   AND variable_name IN (
   SELECT variable_name
     FROM global_variables
    WHERE machine_name = @machine_name
    GROUP BY variable_name
   HAVING COUNT(*) > 1
 )
;
