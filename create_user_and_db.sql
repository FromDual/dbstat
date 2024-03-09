CREATE USER `dbstat`@`localhost` ACCOUNT LOCK PASSWORD EXPIRE;

-- For testing purposes only:
-- DROP USER `dbstat`@`localhost` ;
-- CREATE USER `dbstat`@`localhost` IDENTIFIED BY 'secret';

CREATE DATABASE IF NOT EXISTS `dbstat`;

GRANT SELECT ON *.* TO `dbstat`@`localhost`;
GRANT PROCESS ON *.* TO `dbstat`@`localhost`;

GRANT EVENT ON `dbstat`.* TO `dbstat`@`localhost`;
GRANT INSERT ON `dbstat`.* TO `dbstat`@`localhost`;
GRANT DELETE ON `dbstat`.* TO `dbstat`@`localhost`;
