CREATE TABLE `global_variables` (
  `variable_name` VARCHAR(64) NOT NULL
, `ts` TIMESTAMP NOT NULL
, `variable_value` VARCHAR(4096) NOT NULL
, PRIMARY KEY (`variable_name`, `ts`)
);
ALTER TABLE `global_variables` ADD INDEX (`variable_name`);

DELIMITER //

CREATE OR REPLACE DEFINER = `dbstat`@`localhost` EVENT gather_global_variables
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
  DECLARE done INT DEFAULT FALSE;
  DECLARE name, value_new, value_old VARCHAR(4096);
  DECLARE cur1 CURSOR FOR SELECT LOWER(variable_name) AS variable_name, variable_value FROM information_schema.global_variables WHERE variable_name NOT IN ('gtid_binlog_pos', 'gtid_binlog_state', 'gtid_current_pos');
  DECLARE cur2 CURSOR(name VARCHAR(64)) FOR SELECT variable_value FROM global_variables WHERE variable_name = name;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN cur1;

  gv_loop: LOOP
    FETCH cur1 INTO name, value_new;
    IF done THEN
      LEAVE gv_loop;
    END IF;

    BEGIN

      DECLARE CONTINUE HANDLER FOR NOT FOUND
      BEGIN
        INSERT INTO `global_variables` VALUES (name, CURRENT_TIMESTAMP(), value_new);
      END;

      OPEN cur2(name);
      FETCH cur2 INTO value_old;
      CLOSE cur2;
    END;

    IF value_old != value_new THEN
      INSERT INTO `global_variables` VALUES (name, CURRENT_TIMESTAMP(), value_new);
    END IF;
  END LOOP;

  CLOSE cur1;
END;
//

DELIMITER ;
