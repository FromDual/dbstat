# dbstat
Gathers MariaDB/MySQL database statistics similar to sysstat/sar

Make sure that the Event Scheduler is enabled and running:

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



----

1. tables -> OK
2. processlist -> OK
3. open trx and locks -> OK

4. mdl

For MariaDB

https://mariadb.com/kb/en/metadata-lock-info-plugin/
SELECT *
  FROM performance_schema.threads
 WHERE PROCESSLIST_ID IN (400, 401);

use I_S.processlist

 SELECT mdl.thread_id AS connection_id, CONCAT(pl.user, ' from ', pl.host) AS 'user', mdl.lock_mode, mdl.lock_type, mdl.table_schema, mdl.table_name
          , pl.db AS actual_schema, pl.time, DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL time SECOND) AS startet, pl.command, pl.state, pl.info AS query, pl.query_id
       FROM information_schema.metadata_lock_info AS mdl
       JOIN information_schema.processlist AS pl ON pl.id = mdl.thread_id
      WHERE pl.time > 10
;
+---------------+---------------------+-------------------------+----------------------+--------------+------------+---------------+------+---------------------+---------+---------------------------------+-----------------------------------+----------+
| connection_id | user                | lock_mode               | lock_type            | table_schema | table_name | actual_schema | time | startet             | command | state                           | query                             | query_id |
+---------------+---------------------+-------------------------+----------------------+--------------+------------+---------------+------+---------------------+---------+---------------------------------+-----------------------------------+----------+
|          7383 | root from localhost | MDL_BACKUP_ALTER_COPY   | Backup lock          |              |            | test          | 1581 | 2020-05-27 11:25:16 | Query   | Waiting for table metadata lock | alter table test add column a int |    61933 |
|          7383 | root from localhost | MDL_SHARED_UPGRADABLE   | Table metadata lock  | test         | test       | test          | 1581 | 2020-05-27 11:25:16 | Query   | Waiting for table metadata lock | alter table test add column a int |    61933 |
|          7383 | root from localhost | MDL_INTENTION_EXCLUSIVE | Schema metadata lock | test         |            | test          | 1581 | 2020-05-27 11:25:16 | Query   | Waiting for table metadata lock | alter table test add column a int |    61933 |
|          7382 | root from localhost | MDL_SHARED_READ         | Table metadata lock  | test         | test       | test          | 1623 | 2020-05-27 11:24:34 | Sleep   |                                 | NULL                              |    61850 |
+---------------+---------------------+-------------------------+----------------------+--------------+------------+---------------+------+---------------------+---------+---------------------------------+-----------------------------------+----------+

6. variable changes (from to) infinit

SHOW GLOBAL VARIABLES

7. status (30 days)

SHOW GLOBAL STATUS
