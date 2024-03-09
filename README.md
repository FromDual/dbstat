# dbstat
Gathers MariaDB/MySQL database statistics similar to sysstat/sar

Make sure that the Event Scheduler is enabled and running (on MariaDB it is by default OFF):

SQL> SHOW GLOBAL VARIABLES LIKE 'event_scheduler';

You can enable the Event Scheduler either dynamically with the command:

SQL> SET GLOBAL event_scheduler = ON;

But you have to persist your change in the database configuration file (my.cnf):

[server]
enabled event_scheduler = ON

Check if events are running fine:

SQL> SELECT db, name, definer, execute_at, CONCAT(interval_value, ' ', interval_field) AS 'interval'
          , created, modified, last_executed, starts, ends, status, on_completion
  FROM mysql.event
;
+--------+--------------------+------------------+------------+----------+---------------------+---------------------+---------------------+---------------------+------+---------+---------------+
| db     | name               | definer          | execute_at | interval | created             | modified            | last_executed       | starts              | ends | status  | on_completion |
+--------+--------------------+------------------+------------+----------+---------------------+---------------------+---------------------+---------------------+------+---------+---------------+
| dbstat | gather_table_size  | dbstat@localhost | NULL       | 1 MINUTE | 2024-03-08 18:16:16 | 2024-03-08 18:16:16 | 2024-03-08 19:18:00 | 2024-03-08 01:04:00 | NULL | ENABLED | DROP          |
| dbstat | purge_table_size   | dbstat@localhost | NULL       | 5 MINUTE | 2024-03-08 18:24:55 | 2024-03-08 18:24:55 | 2024-03-08 19:14:55 | 2024-03-08 17:24:55 | NULL | ENABLED | DROP          |
| dbstat | gather_processlist | dbstat@localhost | NULL       | 1 MINUTE | 2024-03-08 19:14:44 | 2024-03-08 19:14:44 | 2024-03-08 19:17:44 | 2024-03-08 18:14:44 | NULL | ENABLED | DROP          |
| dbstat | purge_processlist  | dbstat@localhost | NULL       | 1 MINUTE | 2024-03-08 19:14:50 | 2024-03-08 19:14:50 | 2024-03-08 19:17:50 | 2024-03-08 18:14:50 | NULL | ENABLED | DROP          |
+--------+--------------------+------------------+------------+----------+---------------------+---------------------+---------------------+---------------------+------+---------+---------------+

This scrips where tested on MariaDB 10.6 and 10.11. They possibly need some minior adaption for MySQL 8.0 ff.


----

1. tables -> done
2. processlist -> done
3. open trx and locks -> done
   * Open feautre request: locking trx does not show query
4. mdl -> done
5. variable changes -> done
6. status (30 days) -> open
   SHOW GLOBAL STATUS
