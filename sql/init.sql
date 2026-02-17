-- Create USERS table
CREATE TABLE USERS (
    USER_ID VARCHAR(100) PRIMARY KEY,
    USERNAME VARCHAR(100) NOT NULL UNIQUE,
    FIRSTNAME VARCHAR(100),
    LASTNAME VARCHAR(100),
    MIDDLENAME VARCHAR(100),
    HONORIFICPREFIX VARCHAR(50),
    EMAIL VARCHAR(100) NOT NULL,
    DISPLAYNAME VARCHAR(200),
    NICKNAME VARCHAR(100),
    MOBILEPHONE VARCHAR(50),
    STREETADDRESS VARCHAR(200),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    ZIPCODE VARCHAR(20),
    COUNTRYCODE VARCHAR(10),
    POSTALADDRESS VARCHAR(500),
    TIMEZONE VARCHAR(100),
    DEPARTMENT VARCHAR(100),
    MANAGERID VARCHAR(100),
    WORKLOCATION VARCHAR(200),
    EMERGENCYCONTACT VARCHAR(200),
    PASSWORD_HASH VARCHAR(255),
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    COSTCENTER VARCHAR(100),
    MANAGER VARCHAR(100),
    TITLE VARCHAR(100),
    HIREDATE DATE,
    TERMINATIONDATE DATE,
    BIRTHDATE DATE,
    EMPLOYEENUMBER VARCHAR(50)
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

-- Populate USERS with Star Wars characters from LDIF
-- Password for all users: P@ssword2024!
INSERT INTO USERS (
    USER_ID, USERNAME, FIRSTNAME, LASTNAME, EMAIL, DISPLAYNAME, TITLE, DEPARTMENT,
    MANAGER, MANAGERID, POSTALADDRESS, EMPLOYEENUMBER, PASSWORD_HASH, COSTCENTER, IS_ACTIVE
) VALUES
-- LIGHT SIDE
('luke.skywalker', 'luke.skywalker@galaxy.local', 'Luke', 'Skywalker', 'luke.skywalker@galaxy.local',
 'Luke Skywalker', 'Jedi Knight', 'JEDI-COUNCIL',
 'obiwan.kenobi@galaxy.local', 'obiwan.kenobi@galaxy.local', 'Lars Moisture Farm, Anchorhead, Tatooine', '10021',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Jedi', 1),

('leia.organa', 'leia.organa@galaxy.local', 'Leia', 'Organa', 'leia.organa@galaxy.local',
 'Princess Leia', 'Princess of Alderaan', 'REBEL-COMMAND',
 NULL, NULL, 'Royal Palace, Aldera, Alderaan', '10022',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Resistance', 1),

('han.solo', 'han.solo@galaxy.local', 'Han', 'Solo', 'han.solo@galaxy.local',
 'Han Solo', 'Smuggler Captain', 'FREELANCE',
 'leia.organa@galaxy.local', 'leia.organa@galaxy.local', 'Docking Bay 94, Mos Eisley, Tatooine', '10023',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Resistance', 1),

('obiwan.kenobi', 'obiwan.kenobi@galaxy.local', 'Obi-Wan', 'Kenobi', 'obiwan.kenobi@galaxy.local',
 'Obi-Wan Kenobi', 'Jedi Master', 'JEDI-COUNCIL',
 'yoda@galaxy.local', 'yoda@galaxy.local', 'Dune Sea Hut, Jundland Wastes, Tatooine', '10024',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Jedi', 1),

('yoda', 'yoda@galaxy.local', 'Minch', 'Yoda', 'yoda@galaxy.local',
 'Yoda', 'Grand Jedi Master', 'JEDI-COUNCIL',
 NULL, NULL, 'Hut, Swamp, Dagobah', '900',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Jedi', 1),

('chewbacca', 'chewbacca@galaxy.local', 'Chewbacca', 'Wookiee', 'chewbacca@galaxy.local',
 'Chewbacca', 'First Mate & Wookiee Warrior', 'FREELANCE',
 'han.solo@galaxy.local', 'han.solo@galaxy.local', 'Millennium Falcon Co-pilot Seat, Kashyyyk', '10025',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Resistance', 1),

('padme.amidala', 'padme.amidala@galaxy.local', 'Padmé', 'Amidala', 'padme.amidala@galaxy.local',
 'Padmé', 'Queen of Naboo', 'ROYAL-HOUSE',
 NULL, NULL, 'Theed Royal Palace, Theed, Naboo', '10026',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Resistance', 1),

('lando.calrissian', 'lando.calrissian@galaxy.local', 'Lando', 'Calrissian', 'lando.calrissian@galaxy.local',
 'Lando Calrissian', 'Baron Administrator', 'REBEL-COMMAND',
 NULL, NULL, 'Cloud City, Bespin', '10027',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Resistance', 1),

('qui-gon.jinn', 'qui-gon.jinn@galaxy.local', 'Qui-Gon', 'Jinn', 'qui-gon.jinn@galaxy.local',
 'Qui-Gon Jinn', 'Jedi Master', 'JEDI-COUNCIL',
 NULL, NULL, 'Jedi Temple, Coruscant', '10028',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Jedi', 1),

('mace.windu', 'mace.windu@galaxy.local', 'Mace', 'Windu', 'mace.windu@galaxy.local',
 'Mace Windu', 'Jedi Master', 'JEDI-COUNCIL',
 'yoda@galaxy.local', 'yoda@galaxy.local', 'Jedi Temple, Coruscant', '10029',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Jedi', 1),

-- DARK SIDE
('darth.vader', 'darth.vader@galaxy.local', 'Anakin', 'Skywalker', 'darth.vader@galaxy.local',
 'Darth Vader', 'Dark Lord of the Sith', 'IMPERIAL-HIGH-COMMAND',
 'darth.sidious@galaxy.local', 'darth.sidious@galaxy.local', 'Executor Bridge, Death Star, Galactic Empire', '501',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Empire', 1),

('darth.sidious', 'darth.sidious@galaxy.local', 'Sheev', 'Palpatine', 'darth.sidious@galaxy.local',
 'Darth Sidious', 'Galactic Emperor', 'IMPERIAL-HIGH-COMMAND',
 NULL, NULL, 'The Throne Room, Death Star II, Galactic Empire', '1',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Empire', 1),

('wilhuff.tarkin', 'wilhuff.tarkin@galaxy.local', 'Wilhuff', 'Tarkin', 'wilhuff.tarkin@galaxy.local',
 'Grand Moff Tarkin', 'Grand Moff', 'IMPERIAL-HIGH-COMMAND',
 'darth.sidious@galaxy.local', 'darth.sidious@galaxy.local', 'Death Star Command, Galactic Empire', '101',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Empire', 1),

-- DROIDS
('c3-po', 'c3-po@galaxy.local', 'C3', 'PO', 'c3-po@galaxy.local',
 'C3-PO', 'Protocol Droid', 'DROID-MAINT',
 'leia.organa@galaxy.local', 'leia.organa@galaxy.local', 'Tantive IV, Consular Ship, Alderaan', '10003',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Droid', 1),

('r2-d2', 'r2-d2@galaxy.local', 'R2', 'D2', 'r2-d2@galaxy.local',
 'R2-D2', 'Astromech Droid', 'DROID-MAINT',
 'luke.skywalker@galaxy.local', 'luke.skywalker@galaxy.local', 'X-Wing Fighter, Red 5, Rebel Alliance', '10002',
 '{SSHA}e1NTSEF9aVFFSEV5azhGZzNhd0NHalUwbVRBWDJlcDJwUmYrLzY=', 'Droid', 1);

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
('luke.skywalker', 1, '2025-01-15 09:00:00'),
('luke.skywalker', 2, '2025-01-15 09:00:00'),
('luke.skywalker', 3, '2025-01-15 09:00:00'),
('luke.skywalker', 6, '2025-01-15 09:00:00'),
('luke.skywalker', 7, '2025-01-15 09:00:00'),
('luke.skywalker', 9, '2025-01-15 09:00:00'),

-- Leia Organa (Princess of Alderaan) - Engineering Manager pattern
('leia.organa', 1, '2024-06-01 08:00:00'),
('leia.organa', 2, '2024-06-01 08:00:00'),
('leia.organa', 3, '2024-06-01 08:00:00'),
('leia.organa', 4, '2024-06-01 08:00:00'),
('leia.organa', 5, '2024-06-01 08:00:00'),
('leia.organa', 6, '2024-06-01 08:00:00'),
('leia.organa', 8, '2024-06-01 08:00:00'),
('leia.organa', 9, '2024-06-01 08:00:00'),
('leia.organa', 10, '2024-06-01 08:00:00'),

-- Han Solo (Smuggler Captain) - DevOps Engineer pattern
('han.solo', 1, '2024-09-10 10:00:00'),
('han.solo', 2, '2024-09-10 10:00:00'),
('han.solo', 3, '2024-09-10 10:00:00'),
('han.solo', 6, '2024-09-10 10:00:00'),
('han.solo', 7, '2024-09-10 10:00:00'),
('han.solo', 9, '2024-09-10 10:00:00'),

-- Obi-Wan Kenobi (Jedi Master) - Software Engineer pattern
('obiwan.kenobi', 1, '2025-02-01 09:30:00'),
('obiwan.kenobi', 2, '2025-02-01 09:30:00'),
('obiwan.kenobi', 3, '2025-02-01 09:30:00'),
('obiwan.kenobi', 6, '2025-02-01 09:30:00'),
('obiwan.kenobi', 9, '2025-02-01 09:30:00'),

-- Yoda (Grand Jedi Master) - Product Manager pattern
('yoda', 1, '2024-11-20 11:00:00'),
('yoda', 4, '2024-11-20 11:00:00'),
('yoda', 5, '2024-11-20 11:00:00'),
('yoda', 9, '2024-11-20 11:00:00'),
('yoda', 10, '2024-11-20 11:00:00'),

-- Chewbacca (First Mate) - UX Designer pattern
('chewbacca', 1, '2024-12-05 09:00:00'),
('chewbacca', 5, '2024-12-05 09:00:00'),
('chewbacca', 9, '2024-12-05 09:00:00'),

-- Padmé Amidala (Queen of Naboo) - Director of Product pattern
('padme.amidala', 1, '2023-03-15 08:00:00'),
('padme.amidala', 4, '2023-03-15 08:00:00'),
('padme.amidala', 5, '2023-03-15 08:00:00'),
('padme.amidala', 9, '2023-03-15 08:00:00'),
('padme.amidala', 10, '2023-03-15 08:00:00'),

-- Lando Calrissian (Baron Administrator) - QA Engineer pattern
('lando.calrissian', 1, '2025-01-10 10:00:00'),
('lando.calrissian', 2, '2025-01-10 10:00:00'),
('lando.calrissian', 4, '2025-01-10 10:00:00'),
('lando.calrissian', 6, '2025-01-10 10:00:00'),
('lando.calrissian', 9, '2025-01-10 10:00:00'),

-- Qui-Gon Jinn (Jedi Master) - Business Analyst pattern
('qui-gon.jinn', 1, '2024-10-15 09:00:00'),
('qui-gon.jinn', 4, '2024-10-15 09:00:00'),
('qui-gon.jinn', 5, '2024-10-15 09:00:00'),
('qui-gon.jinn', 9, '2024-10-15 09:00:00'),

-- Mace Windu (Jedi Master) - Junior Developer pattern
('mace.windu', 1, '2025-02-03 09:00:00'),
('mace.windu', 2, '2025-02-03 09:00:00'),
('mace.windu', 6, '2025-02-03 09:00:00'),
('mace.windu', 9, '2025-02-03 09:00:00'),

-- Darth Vader (Dark Lord) - Senior Developer pattern
('darth.vader', 1, '2025-01-15 09:00:00'),
('darth.vader', 2, '2025-01-15 09:00:00'),
('darth.vader', 3, '2025-01-15 09:00:00'),
('darth.vader', 6, '2025-01-15 09:00:00'),
('darth.vader', 7, '2025-01-15 09:00:00'),
('darth.vader', 9, '2025-01-15 09:00:00'),

-- Darth Sidious (Galactic Emperor) - Engineering Manager pattern
('darth.sidious', 1, '2024-06-01 08:00:00'),
('darth.sidious', 2, '2024-06-01 08:00:00'),
('darth.sidious', 3, '2024-06-01 08:00:00'),
('darth.sidious', 4, '2024-06-01 08:00:00'),
('darth.sidious', 5, '2024-06-01 08:00:00'),
('darth.sidious', 6, '2024-06-01 08:00:00'),
('darth.sidious', 8, '2024-06-01 08:00:00'),
('darth.sidious', 9, '2024-06-01 08:00:00'),
('darth.sidious', 10, '2024-06-01 08:00:00'),

-- Wilhuff Tarkin (Grand Moff) - DevOps Engineer pattern
('wilhuff.tarkin', 1, '2024-09-10 10:00:00'),
('wilhuff.tarkin', 2, '2024-09-10 10:00:00'),
('wilhuff.tarkin', 3, '2024-09-10 10:00:00'),
('wilhuff.tarkin', 6, '2024-09-10 10:00:00'),
('wilhuff.tarkin', 7, '2024-09-10 10:00:00'),
('wilhuff.tarkin', 9, '2024-09-10 10:00:00'),

-- C-3PO (Protocol Droid) - Software Engineer pattern
('c3-po', 1, '2025-02-01 09:30:00'),
('c3-po', 2, '2025-02-01 09:30:00'),
('c3-po', 3, '2025-02-01 09:30:00'),
('c3-po', 6, '2025-02-01 09:30:00'),
('c3-po', 9, '2025-02-01 09:30:00'),

-- R2-D2 (Astromech Droid) - Junior Developer pattern
('r2-d2', 1, '2025-02-03 09:00:00'),
('r2-d2', 2, '2025-02-03 09:00:00'),
('r2-d2', 6, '2025-02-03 09:00:00'),
('r2-d2', 9, '2025-02-03 09:00:00');

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
    U.DEPARTMENT,
    U.EMPLOYEENUMBER,
    CONCAT(M.FIRSTNAME, ' ', M.LASTNAME) AS MANAGER_NAME,
    U.MANAGER AS MANAGER_EMAIL,
    U.MANAGERID,
    U.MOBILEPHONE,
    U.POSTALADDRESS,
    U.COSTCENTER,
    U.HIREDATE,
    COUNT(UE.ENT_ID) AS ENTITLEMENT_COUNT,
    U.IS_ACTIVE
FROM USERS U
LEFT JOIN USERS M ON U.MANAGER = M.USER_ID
LEFT JOIN USERENTITLEMENTS UE ON U.USER_ID = UE.USER_ID
WHERE U.IS_ACTIVE = 1
GROUP BY U.USER_ID, U.USERNAME, U.FIRSTNAME, U.LASTNAME, U.MIDDLENAME, U.EMAIL, U.DISPLAYNAME, U.TITLE, U.DEPARTMENT, U.EMPLOYEENUMBER, U.MANAGER, U.MANAGERID, U.MOBILEPHONE, U.POSTALADDRESS, U.COSTCENTER, U.HIREDATE, M.FIRSTNAME, M.LASTNAME, U.IS_ACTIVE;

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
    U.DEPARTMENT,
    U.EMPLOYEENUMBER,
    CONCAT(M.FIRSTNAME, ' ', M.LASTNAME) AS MANAGER_NAME,
    U.MANAGER AS MANAGER_EMAIL,
    U.MANAGERID,
    U.MOBILEPHONE,
    U.POSTALADDRESS,
    U.COSTCENTER,
    U.TERMINATIONDATE,
    COUNT(UE.ENT_ID) AS ENTITLEMENT_COUNT,
    U.IS_ACTIVE
FROM USERS U
LEFT JOIN USERS M ON U.MANAGER = M.USER_ID
LEFT JOIN USERENTITLEMENTS UE ON U.USER_ID = UE.USER_ID
WHERE U.IS_ACTIVE = 0
GROUP BY U.USER_ID, U.USERNAME, U.FIRSTNAME, U.LASTNAME, U.MIDDLENAME, U.EMAIL, U.DISPLAYNAME, U.TITLE, U.DEPARTMENT, U.EMPLOYEENUMBER, U.MANAGER, U.MANAGERID, U.MOBILEPHONE, U.POSTALADDRESS, U.COSTCENTER, U.TERMINATIONDATE, M.FIRSTNAME, M.LASTNAME, U.IS_ACTIVE;

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
    U.DEPARTMENT,
    U.EMPLOYEENUMBER,
    U.MANAGER AS MANAGER_EMAIL,
    U.MANAGERID,
    CONCAT(M.FIRSTNAME, ' ', M.LASTNAME) AS MANAGER_NAME,
    M.TITLE AS MANAGER_TITLE,
    M.DEPARTMENT AS MANAGER_DEPARTMENT,
    U.IS_ACTIVE
FROM USERS U
LEFT JOIN USERS M ON U.MANAGER = M.USER_ID;
