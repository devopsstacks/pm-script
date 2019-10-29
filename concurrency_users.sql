DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ConcurrencyAnalysis`(IN `from_date` DATETIME, IN `to_date` DATETIME, IN `customer` VARCHAR(100), IN `workspace` VARCHAR(100))
    DETERMINISTIC
BEGIN
    SET @start_date = from_date;   
    SET @table_result = CONCAT(customer,'__', workspace, '__concurrency__',DATE_FORMAT(NOW(), '%Y_%m_%d_%H_%i_%s'));
    SET @createTab=CONCAT("CREATE TABLE IF NOT EXISTS ", @table_result, " (id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    concurrency INT(11) NULL,
    time_point DATETIME NULL
    )");
PREPARE stmt FROM @createTab;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
    loop_label:  LOOP
        IF  @start_date > to_date THEN 
            LEAVE  loop_label;
        END  IF;
        
        SET @con_users = (SELECT COUNT(DISTINCT(USR_UID)) FROM LOGIN_LOG WHERE DATE_FORMAT(@start_date, '%Y-%m-%d %H:%i')  BETWEEN DATE_FORMAT(LOGIN_LOG.LOG_INIT_DATE, '%Y-%m-%d %H:%i') AND DATE_FORMAT(LOGIN_LOG.LOG_END_DATE, '%Y-%m-%d %H:%i') LIMIT 1 );
        
    SET @insert_sql = CONCAT("INSERT INTO ", @table_result, " (concurrency, time_point) VALUES (", @con_users, ",'", @start_date,"')");
    PREPARE stmt FROM @insert_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
        SET @start_date = DATE_ADD(@start_date, INTERVAL 1 MINUTE);
    END LOOP;
END$$
DELIMITER ;
