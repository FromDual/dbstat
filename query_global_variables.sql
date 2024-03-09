-- Show all variables which have changed:
SELECT *
  FROM global_variables
 WHERE variable_name IN (
   SELECT variable_name
     FROM global_variables
    GROUP BY variable_name
   HAVING COUNT(*) > 1
 )
;
