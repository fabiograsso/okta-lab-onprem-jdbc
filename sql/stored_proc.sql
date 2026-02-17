-- ============================================================================
-- MySQL Stored Procedures for Okta Generic Database Connector
-- Based on Oracle procedures from Appendix A
-- ============================================================================

DELIMITER $$

-- ----------------------------------------------------------------------------
-- 1. GET_ACTIVEUSERS - Retrieve all active users
-- ----------------------------------------------------------------------------

CREATE PROCEDURE GET_ACTIVEUSERS()
BEGIN
    SELECT
        USER_ID,
        USERNAME,
        FIRSTNAME,
        LASTNAME,
        MIDDLENAME,
        HONORIFICPREFIX,
        EMAIL,
        DISPLAYNAME,
        NICKNAME,
        MOBILEPHONE,
        STREETADDRESS,
        CITY,
        STATE,
        ZIPCODE,
        COUNTRYCODE,
        POSTALADDRESS,
        TIMEZONE,
        DEPARTMENT,
        MANAGERID,
        WORKLOCATION,
        EMERGENCYCONTACT,
        PASSWORD_HASH,
        IS_ACTIVE,
        COSTCENTER,
        MANAGER,
        TITLE,
        HIREDATE,
        TERMINATIONDATE,
        BIRTHDATE,
        EMPLOYEENUMBER
    FROM USERS
    WHERE IS_ACTIVE = 1;
END$$

-- ----------------------------------------------------------------------------
-- 2. GET_ALL_ENTITLEMENTS - Retrieve all entitlements
-- ----------------------------------------------------------------------------

CREATE PROCEDURE GET_ALL_ENTITLEMENTS()
BEGIN
    SELECT 
        ENT_ID, 
        ENT_NAME, 
        ENT_DESCRIPTION 
    FROM ENTITLEMENTS;
END$$

-- ----------------------------------------------------------------------------
-- 3. GET_USER_BY_ID - Retrieve a specific user by ID
-- ----------------------------------------------------------------------------

CREATE PROCEDURE GET_USER_BY_ID(
    IN p_user_id VARCHAR(100)
)
BEGIN
    SELECT
        USER_ID,
        USERNAME,
        FIRSTNAME,
        LASTNAME,
        MIDDLENAME,
        HONORIFICPREFIX,
        EMAIL,
        DISPLAYNAME,
        NICKNAME,
        MOBILEPHONE,
        STREETADDRESS,
        CITY,
        STATE,
        ZIPCODE,
        COUNTRYCODE,
        POSTALADDRESS,
        TIMEZONE,
        DEPARTMENT,
        MANAGERID,
        WORKLOCATION,
        EMERGENCYCONTACT,
        PASSWORD_HASH,
        IS_ACTIVE,
        COSTCENTER,
        MANAGER,
        TITLE,
        HIREDATE,
        TERMINATIONDATE,
        BIRTHDATE,
        EMPLOYEENUMBER
    FROM USERS
    WHERE USER_ID = p_user_id;
END$$

-- ----------------------------------------------------------------------------
-- 4. GET_USER_ENTITLEMENT - Retrieve entitlements for a specific user
-- ----------------------------------------------------------------------------

CREATE PROCEDURE GET_USER_ENTITLEMENT(
    IN p_user_id VARCHAR(100)
)
BEGIN
    SELECT
        UE.USERENTITLEMENT_ID,
        UE.USER_ID,
        U.USERNAME,
        U.EMAIL,
        UE.ENT_ID,
        E.ENT_NAME,
        E.ENT_DESCRIPTION,
        UE.ASSIGNEDDATE
    FROM USERENTITLEMENTS UE
    JOIN USERS U ON UE.USER_ID = U.USER_ID
    JOIN ENTITLEMENTS E ON UE.ENT_ID = E.ENT_ID
    WHERE UE.USER_ID = p_user_id;
END$$

-- ----------------------------------------------------------------------------
-- 5. CREATE_USER - Create a new user
-- Mandatory fields: p_user_id, p_username, p_firstname, p_lastname, p_email
-- All other fields are optional (can be NULL)
-- ----------------------------------------------------------------------------

CREATE PROCEDURE CREATE_USER(
    IN p_user_id VARCHAR(100),
    IN p_username VARCHAR(100),
    IN p_firstname VARCHAR(100),
    IN p_lastname VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_middlename VARCHAR(100),
    IN p_honorificprefix VARCHAR(50),
    IN p_displayname VARCHAR(200),
    IN p_nickname VARCHAR(100),
    IN p_mobilephone VARCHAR(50),
    IN p_streetaddress VARCHAR(200),
    IN p_city VARCHAR(100),
    IN p_state VARCHAR(100),
    IN p_zipcode VARCHAR(20),
    IN p_countrycode VARCHAR(10),
    IN p_postaladdress VARCHAR(500),
    IN p_timezone VARCHAR(100),
    IN p_department VARCHAR(100),
    IN p_managerid VARCHAR(100),
    IN p_worklocation VARCHAR(200),
    IN p_emergencycontact VARCHAR(200),
    IN p_password_hash VARCHAR(255),
    IN p_costcenter VARCHAR(100),
    IN p_manager VARCHAR(100),
    IN p_title VARCHAR(100),
    IN p_hiredate DATE,
    IN p_terminationdate DATE,
    IN p_birthdate DATE,
    IN p_employeenumber VARCHAR(50)
)
BEGIN
    INSERT INTO USERS (
        USER_ID,
        USERNAME,
        FIRSTNAME,
        LASTNAME,
        MIDDLENAME,
        HONORIFICPREFIX,
        EMAIL,
        DISPLAYNAME,
        NICKNAME,
        MOBILEPHONE,
        STREETADDRESS,
        CITY,
        STATE,
        ZIPCODE,
        COUNTRYCODE,
        POSTALADDRESS,
        TIMEZONE,
        DEPARTMENT,
        MANAGERID,
        WORKLOCATION,
        EMERGENCYCONTACT,
        PASSWORD_HASH,
        IS_ACTIVE,
        COSTCENTER,
        MANAGER,
        TITLE,
        HIREDATE,
        TERMINATIONDATE,
        BIRTHDATE,
        EMPLOYEENUMBER
    ) VALUES (
        p_user_id,
        p_username,
        p_firstname,
        p_lastname,
        p_middlename,
        p_honorificprefix,
        p_email,
        p_displayname,
        p_nickname,
        p_mobilephone,
        p_streetaddress,
        p_city,
        p_state,
        p_zipcode,
        p_countrycode,
        p_postaladdress,
        p_timezone,
        p_department,
        p_managerid,
        p_worklocation,
        p_emergencycontact,
        p_password_hash,
        1,
        p_costcenter,
        p_manager,
        p_title,
        p_hiredate,
        p_terminationdate,
        p_birthdate,
        p_employeenumber
    );
END$$

-- ----------------------------------------------------------------------------
-- 6. UPDATE_USER - Update an existing user
-- Mandatory fields: p_user_id, p_username, p_firstname, p_lastname, p_email
-- All other fields are optional (can be NULL)
-- ----------------------------------------------------------------------------

CREATE PROCEDURE UPDATE_USER(
    IN p_user_id VARCHAR(100),
    IN p_username VARCHAR(100),
    IN p_firstname VARCHAR(100),
    IN p_lastname VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_middlename VARCHAR(100),
    IN p_honorificprefix VARCHAR(50),
    IN p_displayname VARCHAR(200),
    IN p_nickname VARCHAR(100),
    IN p_mobilephone VARCHAR(50),
    IN p_streetaddress VARCHAR(200),
    IN p_city VARCHAR(100),
    IN p_state VARCHAR(100),
    IN p_zipcode VARCHAR(20),
    IN p_countrycode VARCHAR(10),
    IN p_postaladdress VARCHAR(500),
    IN p_timezone VARCHAR(100),
    IN p_department VARCHAR(100),
    IN p_managerid VARCHAR(100),
    IN p_worklocation VARCHAR(200),
    IN p_emergencycontact VARCHAR(200),
    IN p_password_hash VARCHAR(255),
    IN p_costcenter VARCHAR(100),
    IN p_manager VARCHAR(100),
    IN p_title VARCHAR(100),
    IN p_hiredate DATE,
    IN p_terminationdate DATE,
    IN p_birthdate DATE,
    IN p_employeenumber VARCHAR(50)
)
BEGIN
    UPDATE USERS SET
        USERNAME = p_username,
        FIRSTNAME = p_firstname,
        LASTNAME = p_lastname,
        MIDDLENAME = p_middlename,
        HONORIFICPREFIX = p_honorificprefix,
        EMAIL = p_email,
        DISPLAYNAME = p_displayname,
        NICKNAME = p_nickname,
        MOBILEPHONE = p_mobilephone,
        STREETADDRESS = p_streetaddress,
        CITY = p_city,
        STATE = p_state,
        ZIPCODE = p_zipcode,
        COUNTRYCODE = p_countrycode,
        POSTALADDRESS = p_postaladdress,
        TIMEZONE = p_timezone,
        DEPARTMENT = p_department,
        MANAGERID = p_managerid,
        WORKLOCATION = p_worklocation,
        EMERGENCYCONTACT = p_emergencycontact,
        PASSWORD_HASH = p_password_hash,
        COSTCENTER = p_costcenter,
        MANAGER = p_manager,
        TITLE = p_title,
        HIREDATE = p_hiredate,
        TERMINATIONDATE = p_terminationdate,
        BIRTHDATE = p_birthdate,
        EMPLOYEENUMBER = p_employeenumber
    WHERE USER_ID = p_user_id;
END$$

-- ----------------------------------------------------------------------------
-- 7. ACTIVATE_USER - Set user as active
-- ----------------------------------------------------------------------------

CREATE PROCEDURE ACTIVATE_USER(
    IN p_user_id VARCHAR(100)
)
BEGIN
    UPDATE USERS 
    SET IS_ACTIVE = 1 
    WHERE USER_ID = p_user_id;
END$$

-- ----------------------------------------------------------------------------
-- 8. DEACTIVATE_USER - Set user as inactive
-- ----------------------------------------------------------------------------

CREATE PROCEDURE DEACTIVATE_USER(
    IN p_user_id VARCHAR(100)
)
BEGIN
    UPDATE USERS 
    SET IS_ACTIVE = 0 
    WHERE USER_ID = p_user_id;
END$$

-- ----------------------------------------------------------------------------
-- 9. ADD_ENTITLEMENT_TO_USER - Assign an entitlement to a user
-- ----------------------------------------------------------------------------

CREATE PROCEDURE ADD_ENTITLEMENT_TO_USER(
    IN p_user_id VARCHAR(100),
    IN p_ent_id INT
)
BEGIN
    INSERT INTO USERENTITLEMENTS (
        USER_ID, 
        ENT_ID, 
        ASSIGNEDDATE
    ) VALUES (
        p_user_id, 
        p_ent_id, 
        NOW()
    );
END$$

-- ----------------------------------------------------------------------------
-- 10. REMOVE_ENTITLEMENT_FROM_USER - Remove an entitlement from a user
-- ----------------------------------------------------------------------------

CREATE PROCEDURE REMOVE_ENTITLEMENT_FROM_USER(
    IN p_user_id VARCHAR(100),
    IN p_ent_id INT
)
BEGIN
    DELETE FROM USERENTITLEMENTS 
    WHERE USER_ID = p_user_id 
    AND ENT_ID = p_ent_id;
END$$




-- Grant EXECUTE permission on all stored procedures in the oktademo database
GRANT EXECUTE ON oktademo.* TO 'oktademo'@'%';

-- Explicitly grant EXECUTE on each stored procedure (for clarity)
GRANT EXECUTE ON PROCEDURE oktademo.GET_ACTIVEUSERS TO 'oktademo'@'%';
GRANT EXECUTE ON PROCEDURE oktademo.GET_ALL_ENTITLEMENTS TO 'oktademo'@'%';
GRANT EXECUTE ON PROCEDURE oktademo.GET_USER_BY_ID TO 'oktademo'@'%';
GRANT EXECUTE ON PROCEDURE oktademo.GET_USER_ENTITLEMENT TO 'oktademo'@'%';
GRANT EXECUTE ON PROCEDURE oktademo.CREATE_USER TO 'oktademo'@'%';
GRANT EXECUTE ON PROCEDURE oktademo.UPDATE_USER TO 'oktademo'@'%';
GRANT EXECUTE ON PROCEDURE oktademo.ACTIVATE_USER TO 'oktademo'@'%';
GRANT EXECUTE ON PROCEDURE oktademo.DEACTIVATE_USER TO 'oktademo'@'%';
GRANT EXECUTE ON PROCEDURE oktademo.ADD_ENTITLEMENT_TO_USER TO 'oktademo'@'%';
GRANT EXECUTE ON PROCEDURE oktademo.REMOVE_ENTITLEMENT_FROM_USER TO 'oktademo'@'%';

-- Flush privileges to ensure changes take effect
FLUSH PRIVILEGES;


DELIMITER ;

-- ============================================================================
-- Example usage and testing
-- ============================================================================

-- Test GET_ACTIVEUSERS
-- CALL GET_ACTIVEUSERS();

-- Test GET_ALL_ENTITLEMENTS
-- CALL GET_ALL_ENTITLEMENTS();

-- Test GET_USER_BY_ID
-- CALL GET_USER_BY_ID('luke.skywalker@galaxy.local');

-- Test GET_USER_ENTITLEMENT
-- CALL GET_USER_ENTITLEMENT('luke.skywalker@galaxy.local');

-- Test CREATE_USER
-- CALL CREATE_USER('test.user@galaxy.local', 'Test', 'User', 'test.user@example.com', 'manager@example.com', 'Developer');

-- Test UPDATE_USER
-- CALL UPDATE_USER('luke.skywalker@galaxy.local', 'Luke', 'Skywalker', 'luke.new@galaxy.local', 'yoda@galaxy.local', 'Jedi Master');

-- Test ACTIVATE_USER
-- CALL ACTIVATE_USER('luke.skywalker@galaxy.local');

-- Test DEACTIVATE_USER
-- CALL DEACTIVATE_USER('luke.skywalker@galaxy.local');

-- Test ADD_ENTITLEMENT_TO_USER
-- CALL ADD_ENTITLEMENT_TO_USER('luke.skywalker@galaxy.local', 5);

-- Test REMOVE_ENTITLEMENT_FROM_USER
-- CALL REMOVE_ENTITLEMENT_FROM_USER('luke.skywalker@galaxy.local', 5);

-- ============================================================================
-- End of stored_proc.sql
-- ============================================================================