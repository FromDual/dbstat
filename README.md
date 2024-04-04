# dbstat
Gathers MariaDB/MySQL database statistics similar to sysstat/sar.

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
     ORDER BY db, name ASC
    ;
    +--------+--------------------+------------------+------------+----------+---------------------+---------------------+---------------------+---------------------+------+---------+---------------+
    | db     | name               | definer          | execute_at | interval | created             | modified            | last_executed       | starts              | ends | status  | on_completion |
    +--------+--------------------+------------------+------------+----------+---------------------+---------------------+---------------------+---------------------+------+---------+---------------+
    | dbstat | gather_table_size  | dbstat@localhost | NULL       | 1 MINUTE | 2024-03-08 18:16:16 | 2024-03-08 18:16:16 | 2024-03-08 19:18:00 | 2024-03-08 01:04:00 | NULL | ENABLED | DROP          |
    | dbstat | purge_table_size   | dbstat@localhost | NULL       | 5 MINUTE | 2024-03-08 18:24:55 | 2024-03-08 18:24:55 | 2024-03-08 19:14:55 | 2024-03-08 17:24:55 | NULL | ENABLED | DROP          |
    | dbstat | gather_processlist | dbstat@localhost | NULL       | 1 MINUTE | 2024-03-08 19:14:44 | 2024-03-08 19:14:44 | 2024-03-08 19:17:44 | 2024-03-08 18:14:44 | NULL | ENABLED | DROP          |
    | dbstat | purge_processlist  | dbstat@localhost | NULL       | 1 MINUTE | 2024-03-08 19:14:50 | 2024-03-08 19:14:50 | 2024-03-08 19:17:50 | 2024-03-08 18:14:50 | NULL | ENABLED | DROP          |
    +--------+--------------------+------------------+------------+----------+---------------------+---------------------+---------------------+---------------------+------+---------+---------------+

For errors in EVENTs please check the MariaDB Error Log (log_error or journalctl -xeu mariadb).

## Restrictions

If you want to have the events enabled on the slave as well make sure you enable them on slave explicitly. In a Master/Master topology you have to work with sql_log_bin = off to not disable it on the other site again... This restriction is lifted with MariaDB 11.5.2? and newer.

If you enable the events on master and slave simultaneously you have to make sure that AUTO_INCREMENT_INCREMENT (2) and AUTO_INCREMENT_OFFSET (1/2) are set accordingly. Otherwise replication will break!

Replication will further break if Master and Slave (or Galera nodes?) are on the same machine!

These scrips where tested on MariaDB 10.6 and 10.11 (and 11.5.0). They possibly need some minor adaption for MySQL/Percona Server 8.0 ff.

## Features

1. table_size -> done
   * Tablesize deleting after 30 days is bad idea. we should possibly aggregate per week or month and keep forever?
2. processlist -> done
3. open trx and locks -> done
   * Open feature request: Locking trx does not show query
4. metadata lock -> done
5. variable changes -> done
6. status (30 days) -> done
   * 1/min too often?
   * store delta as well?
7. I_S.innodb_metrics -> open
8. General
   sql_mode = 'ONLY_FULL_GROUP_BY' should work correctly!!! -> done

## Table size

Customer thought it would be good to know which tables grow how fast in a multi-tenant environment.

## Processlist

Customers sometimes get the "Too many connections" error. And they do not know why. This information should be available now with the processlist part.

## Open transactions and locks

Customers sometimes have open and/or long running transactions and they do not know them. trx_and_lck should show them.

## Metadata locks

Same situation with metadata locks. Sometimes they get the "Too many connections" error. So metadata locks should be visible now with the metadata_lock part.

## Variable changes

When was a variable changed? This question cannot be answered sometimes. With this module it should become clear when (not why and not who).

## Global Status

This is the main sar/sysstat part. Keep all GLOBAL STATUS counters available for a certain amount of time. Most customers do not have a monitoring put in place. This feature should help a bit to work around.
