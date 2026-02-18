-- Create USERS table
CREATE TABLE USERS (
    USER_ID VARCHAR(100) PRIMARY KEY,
    USERNAME VARCHAR(100) NOT NULL UNIQUE,
    FIRSTNAME VARCHAR(100) NOT NULL,
    LASTNAME VARCHAR(100) NOT NULL,
    MIDDLENAME VARCHAR(100),
    EMAIL VARCHAR(100) NOT NULL,
    DISPLAYNAME VARCHAR(200),
    NICKNAME VARCHAR(100),
    MOBILEPHONE VARCHAR(50),
    STREETADDRESS VARCHAR(200),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    ZIPCODE VARCHAR(20),
    COUNTRYCODE VARCHAR(10),
    TIMEZONE VARCHAR(100),
    ORGANIZATION VARCHAR(100),
    DEPARTMENT VARCHAR(100),
    MANAGERID VARCHAR(100),
    MANAGER VARCHAR(100),
    TITLE VARCHAR(100),
    EMPLOYEENUMBER VARCHAR(50),
    HIREDATE DATE,
    TERMINATIONDATE DATE,
    PASSWORD_HASH VARCHAR(255),
    IS_ACTIVE BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- Create ENTITLEMENTS table
CREATE TABLE ENTITLEMENTS (
    ENT_ID INT PRIMARY KEY,
    ENT_NAME VARCHAR(100) NOT NULL UNIQUE,
    ENT_DESCRIPTION VARCHAR(255)
) ENGINE=InnoDB;

-- Create USERENTITLEMENTS junction table
CREATE TABLE USERENTITLEMENTS (
    USERENTITLEMENT_ID UUID PRIMARY KEY DEFAULT (UUID()),
    USER_ID VARCHAR(100) NOT NULL,
    ENT_ID INT NOT NULL,
    ASSIGNEDDATE DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user FOREIGN KEY (USER_ID) REFERENCES USERS(USER_ID) ON DELETE CASCADE,
    CONSTRAINT fk_entitlement FOREIGN KEY (ENT_ID) REFERENCES ENTITLEMENTS(ENT_ID) ON DELETE CASCADE,
    UNIQUE KEY unique_user_entitlement (USER_ID, ENT_ID)
) ENGINE=InnoDB;

-- Populate USERS with Star Wars characters as test data with extended attributes
-- Password for all users: P@ssword2024!
INSERT INTO USERS (
    USER_ID, USERNAME, FIRSTNAME, LASTNAME, EMAIL, DISPLAYNAME, TITLE, ORGANIZATION, DEPARTMENT,
    MANAGERID, MANAGER, EMPLOYEENUMBER, PASSWORD_HASH, IS_ACTIVE
) VALUES
-- LIGHT SIDE
('LUKE.SKYWALKER', 'luke.skywalker@galaxy.local', 'Luke', 'Skywalker', 'luke.skywalker@galaxy.local',
 'Luke Skywalker', 'Jedi Knight', 'Jedi', 'JEDI-COUNCIL',
 'obiwan.kenobi@galaxy.local', 'Obiwan Kenobi', '10021',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('LEIA.ORGANA', 'leia.organa@galaxy.local', 'Leia', 'Organa', 'leia.organa@galaxy.local',
 'Princess Leia', 'Princess of Alderaan', 'Resistance', 'REBEL-COMMAND',
 NULL, NULL, '10022',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('HAN.SOLO', 'han.solo@galaxy.local', 'Han', 'Solo', 'han.solo@galaxy.local',
 'Han Solo', 'Smuggler Captain', 'Resistance', 'FREELANCE',
 'leia.organa@galaxy.local', 'Leia Organa', '10023',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('OBIWAN.KENOBI', 'obiwan.kenobi@galaxy.local', 'Obi-Wan', 'Kenobi', 'obiwan.kenobi@galaxy.local',
 'Obi-Wan Kenobi', 'Jedi Master', 'Jedi', 'JEDI-COUNCIL',
 'yoda@galaxy.local', 'Yoda', '10024',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('YODA', 'yoda@galaxy.local', 'Minch', 'Yoda', 'yoda@galaxy.local',
 'Yoda', 'Grand Jedi Master', 'Jedi', 'JEDI-COUNCIL',
 NULL, NULL, '900',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('CHEWBACCA', 'chewbacca@galaxy.local', 'Chewbacca', 'Wookiee', 'chewbacca@galaxy.local',
 'Chewbacca', 'First Mate & Wookiee Warrior', 'Resistance', 'FREELANCE',
 'han.solo@galaxy.local', 'Han Solo', '10025',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('PADME.AMIDALA', 'padme.amidala@galaxy.local', 'Padmé', 'Amidala', 'padme.amidala@galaxy.local',
 'Padmé', 'Queen of Naboo', 'Resistance', 'ROYAL-HOUSE',
 NULL, NULL, '10026',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('LANDO.CALRISSIAN', 'lando.calrissian@galaxy.local', 'Lando', 'Calrissian', 'lando.calrissian@galaxy.local',
 'Lando Calrissian', 'Baron Administrator', 'Resistance', 'REBEL-COMMAND',
 NULL, NULL, '10027',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('QUI-GON.JINN', 'qui-gon.jinn@galaxy.local', 'Qui-Gon', 'Jinn', 'qui-gon.jinn@galaxy.local',
 'Qui-Gon Jinn', 'Jedi Master', 'Jedi', 'JEDI-COUNCIL',
 NULL, NULL, '10028',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('MACE.WINDU', 'mace.windu@galaxy.local', 'Mace', 'Windu', 'mace.windu@galaxy.local',
 'Mace Windu', 'Jedi Master', 'Jedi', 'JEDI-COUNCIL',
 'yoda@galaxy.local', 'Yoda', '10029',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

-- DARK SIDE
('DARTH.VADER', 'darth.vader@galaxy.local', 'Anakin', 'Skywalker', 'darth.vader@galaxy.local',
 'Darth Vader', 'Dark Lord of the Sith', 'Empire', 'IMPERIAL-HIGH-COMMAND',
 'darth.sidious@galaxy.local', 'Darth Sidious', '501',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('DARTH.SIDIOUS', 'darth.sidious@galaxy.local', 'Sheev', 'Palpatine', 'darth.sidious@galaxy.local',
 'Darth Sidious', 'Galactic Emperor', 'Empire', 'IMPERIAL-HIGH-COMMAND',
 NULL, NULL, '1',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('WILHUFF.TARKIN', 'wilhuff.tarkin@galaxy.local', 'Wilhuff', 'Tarkin', 'wilhuff.tarkin@galaxy.local',
 'Grand Moff Tarkin', 'Grand Moff', 'Empire', 'IMPERIAL-HIGH-COMMAND',
 'darth.sidious@galaxy.local', 'Darth Sidious', '101',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

-- DROIDS
('C3-PO', 'c3-po@galaxy.local', 'C3', 'PO', 'c3-po@galaxy.local',
 'C3-PO', 'Protocol Droid', 'Droid', 'DROID-MAINT',
 'leia.organa@galaxy.local', 'Leia Organa', '10003',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1),

('R2-D2', 'r2-d2@galaxy.local', 'R2', 'D2', 'r2-d2@galaxy.local',
 'R2-D2', 'Astromech Droid', 'Droid', 'DROID-MAINT',
 'luke.skywalker@galaxy.local', 'Luke Skywalker', '10002',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 1);

-- Populate ENTITLEMENTS
INSERT INTO ENTITLEMENTS (ENT_ID, ENT_NAME, ENT_DESCRIPTION) VALUES
('1', 'VPN Access', 'Access to company VPN'),
('2', 'GitHub Admin', 'Administrative access to GitHub repositories'),
('3', 'AWS Console', 'Access to AWS Management Console'),
('4', 'Jira Admin', 'Administrative access to Jira'),
('5', 'Confluence Edit', 'Edit permissions in Confluence'),
('6', 'Database Read', 'Read-only access to production databases'),
('7', 'Database Write', 'Write access to production databases'),
('8', 'Slack Admin', 'Administrative access to Slack workspace'),
('9', 'Office 365', 'Microsoft Office 365 license'),
('10', 'Salesforce', 'Access to Salesforce CRM');

-- Populate USERENTITLEMENTS (assign entitlements to users)
INSERT INTO USERENTITLEMENTS (USER_ID, ENT_ID, ASSIGNEDDATE) VALUES

-- Luke Skywalker (Jedi Knight) - Senior Developer pattern
('LUKE.SKYWALKER', 1, '2025-01-15 09:00:00'),
('LUKE.SKYWALKER', 2, '2025-01-15 09:00:00'),
('LUKE.SKYWALKER', 3, '2025-01-15 09:00:00'),
('LUKE.SKYWALKER', 6, '2025-01-15 09:00:00'),
('LUKE.SKYWALKER', 7, '2025-01-15 09:00:00'),
('LUKE.SKYWALKER', 9, '2025-01-15 09:00:00'),

-- Leia Organa (Princess of Alderaan) - Engineering Manager pattern
('LEIA.ORGANA', 1, '2024-06-01 08:00:00'),
('LEIA.ORGANA', 2, '2024-06-01 08:00:00'),
('LEIA.ORGANA', 3, '2024-06-01 08:00:00'),
('LEIA.ORGANA', 4, '2024-06-01 08:00:00'),
('LEIA.ORGANA', 5, '2024-06-01 08:00:00'),
('LEIA.ORGANA', 6, '2024-06-01 08:00:00'),
('LEIA.ORGANA', 8, '2024-06-01 08:00:00'),
('LEIA.ORGANA', 9, '2024-06-01 08:00:00'),
('LEIA.ORGANA', 10, '2024-06-01 08:00:00'),

-- Han Solo (Smuggler Captain) - DevOps Engineer pattern
('HAN.SOLO', 1, '2024-09-10 10:00:00'),
('HAN.SOLO', 2, '2024-09-10 10:00:00'),
('HAN.SOLO', 3, '2024-09-10 10:00:00'),
('HAN.SOLO', 6, '2024-09-10 10:00:00'),
('HAN.SOLO', 7, '2024-09-10 10:00:00'),
('HAN.SOLO', 9, '2024-09-10 10:00:00'),

-- Obi-Wan Kenobi (Jedi Master) - Software Engineer pattern
('OBIWAN.KENOBI', 1, '2025-02-01 09:30:00'),
('OBIWAN.KENOBI', 2, '2025-02-01 09:30:00'),
('OBIWAN.KENOBI', 3, '2025-02-01 09:30:00'),
('OBIWAN.KENOBI', 6, '2025-02-01 09:30:00'),
('OBIWAN.KENOBI', 9, '2025-02-01 09:30:00'),

-- Yoda (Grand Jedi Master) - Product Manager pattern
('YODA', 1, '2024-11-20 11:00:00'),
('YODA', 4, '2024-11-20 11:00:00'),
('YODA', 5, '2024-11-20 11:00:00'),
('YODA', 9, '2024-11-20 11:00:00'),
('YODA', 10, '2024-11-20 11:00:00'),

-- Chewbacca (First Mate) - UX Designer pattern
('CHEWBACCA', 1, '2024-12-05 09:00:00'),
('CHEWBACCA', 5, '2024-12-05 09:00:00'),
('CHEWBACCA', 9, '2024-12-05 09:00:00'),

-- Padmé Amidala (Queen of Naboo) - Director of Product pattern
('PADME.AMIDALA', 1, '2023-03-15 08:00:00'),
('PADME.AMIDALA', 4, '2023-03-15 08:00:00'),
('PADME.AMIDALA', 5, '2023-03-15 08:00:00'),
('PADME.AMIDALA', 9, '2023-03-15 08:00:00'),
('PADME.AMIDALA', 10, '2023-03-15 08:00:00'),

-- Lando Calrissian (Baron Administrator) - QA Engineer pattern
('LANDO.CALRISSIAN', 1, '2025-01-10 10:00:00'),
('LANDO.CALRISSIAN', 2, '2025-01-10 10:00:00'),
('LANDO.CALRISSIAN', 4, '2025-01-10 10:00:00'),
('LANDO.CALRISSIAN', 6, '2025-01-10 10:00:00'),
('LANDO.CALRISSIAN', 9, '2025-01-10 10:00:00'),

-- Qui-Gon Jinn (Jedi Master) - Business Analyst pattern
('QUI-GON.JINN', 1, '2024-10-15 09:00:00'),
('QUI-GON.JINN', 4, '2024-10-15 09:00:00'),
('QUI-GON.JINN', 5, '2024-10-15 09:00:00'),
('QUI-GON.JINN', 9, '2024-10-15 09:00:00'),

-- Mace Windu (Jedi Master) - Junior Developer pattern
('MACE.WINDU', 1, '2025-02-03 09:00:00'),
('MACE.WINDU', 2, '2025-02-03 09:00:00'),
('MACE.WINDU', 6, '2025-02-03 09:00:00'),
('MACE.WINDU', 9, '2025-02-03 09:00:00'),

-- Darth Vader (Dark Lord) - Senior Developer pattern
('DARTH.VADER', 1, '2025-01-15 09:00:00'),
('DARTH.VADER', 2, '2025-01-15 09:00:00'),
('DARTH.VADER', 3, '2025-01-15 09:00:00'),
('DARTH.VADER', 6, '2025-01-15 09:00:00'),
('DARTH.VADER', 7, '2025-01-15 09:00:00'),
('DARTH.VADER', 9, '2025-01-15 09:00:00'),

-- Darth Sidious (Galactic Emperor) - Engineering Manager pattern
('DARTH.SIDIOUS', 1, '2024-06-01 08:00:00'),
('DARTH.SIDIOUS', 2, '2024-06-01 08:00:00'),
('DARTH.SIDIOUS', 3, '2024-06-01 08:00:00'),
('DARTH.SIDIOUS', 4, '2024-06-01 08:00:00'),
('DARTH.SIDIOUS', 5, '2024-06-01 08:00:00'),
('DARTH.SIDIOUS', 6, '2024-06-01 08:00:00'),
('DARTH.SIDIOUS', 8, '2024-06-01 08:00:00'),
('DARTH.SIDIOUS', 9, '2024-06-01 08:00:00'),
('DARTH.SIDIOUS', 10, '2024-06-01 08:00:00'),

-- Wilhuff Tarkin (Grand Moff) - DevOps Engineer pattern
('WILHUFF.TARKIN', 1, '2024-09-10 10:00:00'),
('WILHUFF.TARKIN', 2, '2024-09-10 10:00:00'),
('WILHUFF.TARKIN', 3, '2024-09-10 10:00:00'),
('WILHUFF.TARKIN', 6, '2024-09-10 10:00:00'),
('WILHUFF.TARKIN', 7, '2024-09-10 10:00:00'),
('WILHUFF.TARKIN', 9, '2024-09-10 10:00:00'),

-- C-3PO (Protocol Droid) - Software Engineer pattern
('C3-PO', 1, '2025-02-01 09:30:00'),
('C3-PO', 2, '2025-02-01 09:30:00'),
('C3-PO', 3, '2025-02-01 09:30:00'),
('C3-PO', 6, '2025-02-01 09:30:00'),
('C3-PO', 9, '2025-02-01 09:30:00'),

-- R2-D2 (Astromech Droid) - Junior Developer pattern
('R2-D2', 1, '2025-02-03 09:00:00'),
('R2-D2', 2, '2025-02-03 09:00:00'),
('R2-D2', 6, '2025-02-03 09:00:00'),
('R2-D2', 9, '2025-02-03 09:00:00');

-- =========================================
-- VIEWS - For easier visualization
-- =========================================

-- View that shows user entitlements with readable names
CREATE OR REPLACE VIEW V_USERENTITLEMENTS AS
SELECT 
    UE.ENT_ID,
    E.ENT_NAME,
    UE.USER_ID,
    CONCAT(U.FIRSTNAME, ' ', U.LASTNAME) AS FULLNAME,
    U.EMAIL,
    UE.ASSIGNEDDATE
FROM USERENTITLEMENTS UE
JOIN USERS U ON UE.USER_ID = U.USER_ID
JOIN ENTITLEMENTS E ON UE.ENT_ID = E.ENT_ID;

-- View that shows entitlements of inactive users
CREATE OR REPLACE VIEW V_INACTIVE_USERENTITLEMENTS AS
SELECT 
    UE.USER_ID,
    CONCAT(U.FIRSTNAME, ' ', U.LASTNAME) AS FULLNAME,
    UE.ENT_ID,
    E.ENT_NAME,
    U.EMAIL,
    UE.ASSIGNEDDATE
FROM USERENTITLEMENTS UE
JOIN USERS U ON UE.USER_ID = U.USER_ID
JOIN ENTITLEMENTS E ON UE.ENT_ID = E.ENT_ID
WHERE U.IS_ACTIVE = 0;

-- View that shows active users with their details and entitlement count
CREATE OR REPLACE VIEW V_ACTIVE_USERS AS
SELECT
    U.USER_ID,
    U.USERNAME,
    CONCAT(U.FIRSTNAME, ' ', U.LASTNAME) AS FULLNAME,
    U.FIRSTNAME,
    U.LASTNAME,
    U.MIDDLENAME,
    U.EMAIL,
    U.DISPLAYNAME,
    U.TITLE,
    U.ORGANIZATION,
    U.DEPARTMENT,
    U.EMPLOYEENUMBER,
    CONCAT(M.FIRSTNAME, ' ', M.LASTNAME) AS MANAGER_NAME,
    U.MANAGER AS MANAGER_EMAIL,
    U.MANAGERID,
    U.MOBILEPHONE,
    U.HIREDATE,
    COUNT(UE.ENT_ID) AS ENTITLEMENT_COUNT,
    U.IS_ACTIVE
FROM USERS U
LEFT JOIN USERS M ON U.MANAGER = M.USER_ID
LEFT JOIN USERENTITLEMENTS UE ON U.USER_ID = UE.USER_ID
WHERE U.IS_ACTIVE = 1
GROUP BY U.USER_ID, U.USERNAME, U.FIRSTNAME, U.LASTNAME, U.MIDDLENAME, U.EMAIL, U.DISPLAYNAME, U.TITLE, U.ORGANIZATION, U.DEPARTMENT, U.EMPLOYEENUMBER, U.MANAGER, U.MANAGERID, U.MOBILEPHONE, U.HIREDATE, M.FIRSTNAME, M.LASTNAME, U.IS_ACTIVE;

-- View that shows inactive users with their details and entitlement count
CREATE OR REPLACE VIEW V_INACTIVE_USERS AS
SELECT
    U.USER_ID,
    U.USERNAME,
    CONCAT(U.FIRSTNAME, ' ', U.LASTNAME) AS FULLNAME,
    U.FIRSTNAME,
    U.LASTNAME,
    U.MIDDLENAME,
    U.EMAIL,
    U.DISPLAYNAME,
    U.TITLE,
    U.ORGANIZATION,
    U.DEPARTMENT,
    U.EMPLOYEENUMBER,
    CONCAT(M.FIRSTNAME, ' ', M.LASTNAME) AS MANAGER_NAME,
    U.MANAGER AS MANAGER_EMAIL,
    U.MANAGERID,
    U.MOBILEPHONE,
    U.TERMINATIONDATE,
    COUNT(UE.ENT_ID) AS ENTITLEMENT_COUNT,
    U.IS_ACTIVE
FROM USERS U
LEFT JOIN USERS M ON U.MANAGER = M.USER_ID
LEFT JOIN USERENTITLEMENTS UE ON U.USER_ID = UE.USER_ID
WHERE U.IS_ACTIVE = 0
GROUP BY U.USER_ID, U.USERNAME, U.FIRSTNAME, U.LASTNAME, U.MIDDLENAME, U.EMAIL, U.DISPLAYNAME, U.TITLE, U.ORGANIZATION, U.DEPARTMENT, U.EMPLOYEENUMBER, U.MANAGER, U.MANAGERID, U.MOBILEPHONE, U.TERMINATIONDATE, M.FIRSTNAME, M.LASTNAME, U.IS_ACTIVE;

-- View that shows entitlements with user count
CREATE OR REPLACE VIEW V_ENTITLEMENT_USAGE AS
SELECT 
    E.ENT_ID,
    E.ENT_NAME,
    E.ENT_DESCRIPTION,
    COUNT(UE.USER_ID) AS USER_COUNT,
    GROUP_CONCAT(CONCAT(U.FIRSTNAME, ' ', U.LASTNAME) ORDER BY U.LASTNAME SEPARATOR ', ') AS ASSIGNED_USERS
FROM ENTITLEMENTS E
LEFT JOIN USERENTITLEMENTS UE ON E.ENT_ID = UE.ENT_ID
LEFT JOIN USERS U ON UE.USER_ID = U.USER_ID
GROUP BY E.ENT_ID, E.ENT_NAME, E.ENT_DESCRIPTION;

-- View that shows organizational hierarchy
CREATE OR REPLACE VIEW V_USER_HIERARCHY AS
SELECT
    U.USER_ID,
    U.USERNAME,
    CONCAT(U.FIRSTNAME, ' ', U.LASTNAME) AS FULLNAME,
    U.EMAIL,
    U.DISPLAYNAME,
    U.TITLE,
    U.ORGANIZATION,
    U.DEPARTMENT,
    U.EMPLOYEENUMBER,
    U.MANAGER,
    U.MANAGERID,
    CONCAT(M.FIRSTNAME, ' ', M.LASTNAME) AS MANAGER_NAME,
    M.TITLE AS MANAGER_TITLE,
    M.ORGANIZATION AS MANAGER_ORGANIZATION,
    M.DEPARTMENT AS MANAGER_DEPARTMENT,
    U.IS_ACTIVE
FROM USERS U
LEFT JOIN USERS M ON U.MANAGERID = M.USER_ID;
