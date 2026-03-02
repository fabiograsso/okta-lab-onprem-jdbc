# Okta Provisioning Configuration Guide

This guide provides detailed instructions for configuring the Okta Generic Database Connector to use MySQL stored procedures for user provisioning operations.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Database Schema Reference](#database-schema-reference)
- [Stored Procedures Reference](#stored-procedures-reference)
- [Create Generic Database Connector Application](#create-generic-database-connector-application)
- [Configuration Steps](#configuration-steps)
  - [Import Operations (To Okta)](#import-operations-to-okta)
  - [Provisioning Operations (To App)](#provisioning-operations-to-app)
- [Configure User Lifecycle Management](#configure-user-lifecycle-management)
  - [Add Custom Attributes to Application User Profile](#add-custom-attributes-to-application-user-profile)
  - [Mapping User Attributes](#mapping-user-attributes)
  - [Import & Provisioning](#import--provisioning)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Overview

The Generic Database Connector in Okta supports two types of operations:
- **Import Operations (To Okta)**: Import users and entitlements from your database into Okta
- **Provisioning Operations (To App)**: Create, update, activate, deactivate users and manage entitlements

This lab environment uses stored procedures to handle these operations, providing a clean abstraction layer between Okta and the database.

## Prerequisites

Before configuring Okta provisioning, ensure:
1. ✅ OPP Agent is running and connected to Okta
2. ✅ SCIM Server is running  
3. ✅ Database is initialized with schema and stored procedures (from `sql/init.sql` and `sql/stored_proc.sql`)

## Database Schema Reference

This configuration uses the following database tables:

| Table | Description | Key Fields |
|-------|-------------|------------|
| **USERS** | User profiles | USER_ID (PK), USERNAME, FIRSTNAME, LASTNAME, EMAIL, MANAGER, TITLE, IS_ACTIVE |
| **ENTITLEMENTS** | Available entitlements | ENT_ID (PK), ENT_NAME, ENT_DESCRIPTION |
| **USERENTITLEMENTS** | User-entitlement mappings | USERENTITLEMENT_ID (PK), USER_ID (FK), ENT_ID (FK), ASSIGNEDDATE |

The lab includes 15 test users (Star Wars characters) and 10 pre-configured entitlements.

## Stored Procedures Reference

All stored procedures are defined in `sql/stored_proc.sql`:

| Procedure | Parameters | Purpose |
|-----------|------------|---------|
| `GET_ACTIVEUSERS()` | None | Retrieve all active users |
| `GET_ALL_ENTITLEMENTS()` | None | Retrieve all entitlements |
| `GET_USER_BY_ID(p_user_id)` | p_user_id VARCHAR(100) | Get specific user details |
| `GET_USER_ENTITLEMENT(p_user_id)` | p_user_id VARCHAR(100) | Get user's entitlements |
| `CREATE_USER(...)` | 7 parameters | Create new user |
| `UPDATE_USER(...)` | 7 parameters | Update existing user |
| `ACTIVATE_USER(p_user_id)` | p_user_id VARCHAR(100) | Activate user account |
| `DEACTIVATE_USER(p_user_id)` | p_user_id VARCHAR(100) | Deactivate user account |
| `ADD_ENTITLEMENT_TO_USER(...)` | p_user_id, p_ent_id | Assign entitlement |
| `REMOVE_ENTITLEMENT_FROM_USER(...)` | p_user_id, p_ent_id | Revoke entitlement |

## Create Generic Database Connector Application

Before configuring the provisioning operations, you need to create the Generic Database Connector application in your Okta org.

### Steps to Create the Application

1. **Navigate to Applications**
   - Log on to **Okta Admin Console**
   - Navigate to **Applications** → **Browse App Catalog**

2. **Search for Generic Database Connector**
   - In the search box, type **"Generic Database Connector"**
   - Select **"On-prem connector for Generic Databases"** from the results

   ![Search for Generic Database Connector](img/create-app-1.png)

3. **Add the Integration**
   - Click **Add Integration**

   ![Add Integration](img/create-app-2.png)

4. **Configure Application Label**
   - Provide a name for the application in the **Application Label** field
   - Default name: "Generic Database Connector"
   - Click **Next**

   ![Application Label](img/create-app-3.png)

5. **Complete Setup**
   - Leave the fields to default
   - Click **Done**

6. **Enable Entitlement Management**
   - In the **General** tab, scroll down to the **Entitlement Management** section
   - Click **Edit**
   - From the dropdown menu, select **Enable**
   - Click **Save**

   ![Enable Entitlement Management](img/create-app-4.png)

   > **Note**: Once entitlement management is enabled, you'll notice that the **Governance** tab now shows additional sub-tabs such as **Entitlements**, **Bundles**, etc.

7. **Enable Provisioning**
   - Navigate to the **Provisioning** tab
   - Click **Enable Provisioning**

   ![Enable Provisioning](img/create-app-5.png)

8. **Select OPP Agent**
   - Select your registered Okta Provisioning Agent from the list
   - This page displays all available Okta Provisioning Agents (both active and inactive) in your Okta org
   - Click **Next**

   ![Select Agent](img/create-app-6.png)

9. **Configure SCIM Server Connection**
   - Enter the **SCIM Hostname**: `okta-scim` (must match the container name for internal connectivity)
   - Enter the **API Token** with the `Bearer ` prefix (from SCIM Server credentials)
     - Example: `Bearer da655feabd8ec0c3f89c1fb6e9f0ad39`
   - Click **Add Files** under **Public Key**
   - Upload the certificate file (`.crt`) from `./data/okta-scim/certs/OktaOnPremScimServer-*.crt`
   - Click **Next**

   ![Configure SCIM Connection](img/create-app-7.png)

10. **Configure Database Connection**
    - Provide the database connection details:
      - **Username**: `oktademo` (or from your `.env` file)
      - **Password**: `oktademo` (or from your `.env` file)
      - **Type of Database**: Select **MySQL**
      - **IP/Domain Name**: `db` (Docker container name)
      - **Port**: `3306`
      - **Database Name**: `oktademo` (or from your `.env` file)
    - Click **Connect agents**

    ![Configure Database Connection](img/create-app-8.png)

> **Important**: Once the connection is successful, you'll be directed to the **Integration** tab of the **Provisioning** section. From here, you can proceed to configure Schema Discovery & Import and Provisioning operations.

## Configuration Steps

### Import Operations (To Okta)

These operations import data from your database into Okta.

#### Navigate to Import Settings

1. Go to **Okta Admin Console** → **Applications** → **Generic Database Connector**
2. Navigate to the **Provisioning** tab
3. Go to **Integration** → **To Okta**
4. Click **Edit** next to **Schema discovery & Import**

![Provisioning tab for an On-prem connector for Generic Databases](img/image.png)

---

#### 1. Get Users

Import all active users from the database.

![Get Users Configuration](img/image-1.png)

**Configuration:**
- ✅ Check **Enabled**
- Option 1 - Select **SQL Satement**
   1. Enter SQL query:
      ```sql
      SELECT USER_ID, USERNAME, FIRSTNAME, LASTNAME, EMAIL FROM USERS WHERE IS_ACTIVE = 1
      ```
- Option 2 - Select **Stored Procedure**
   1. Enter stored procedure call:
      ```sql
      CALL GET_ACTIVEUSERS
      ```
   2. **Parameter 1:**
      - Type: `CURSOR`
      - Cursor Type: `REFCURSOR`
   3. **User ID Column:** `USER_ID`

**What it does:** Retrieves all users where `IS_ACTIVE = 1` from the USERS table.

---

#### 2. Get All Entitlements

Import all available entitlements from the database.

![Get All Entitlements Configuration](img/image-2.png)

**Configuration:**
1. ✅ Check **Enabled**
2. Select **Stored Procedure**
3. Enter stored procedure call:
   ```sql
   CALL GET_ALL_ENTITLEMENTS
   ```
4. **Parameter 1:**
   - Type: `CURSOR`
   - Cursor Type: `REFCURSOR`
5. **Entitlement ID Column:** `ENT_ID`
6. **Entitlement Display Column:** `ENT_NAME`

**What it does:** Retrieves all entitlements from the ENTITLEMENTS table (e.g., VPN Access, GitHub Admin, AWS Console).

---

#### 3. Get User by ID

Retrieve specific user details by their USER_ID.

![Get User by ID Configuration](img/image-3.png)

**Configuration:**
1. ✅ Check **Enabled**
2. Select **Stored Procedure**
3. Enter stored procedure call:
   ```sql
   CALL GET_USER_BY_ID(?)
   ```
4. **Parameter 1:**
   - Type: `DATABASE_FIELD`
   - Field Value: `USER_ID`

**What it does:** Queries a specific user from the USERS table using their USER_ID.

---

#### 4. Get User Entitlements

Retrieve all entitlements assigned to a specific user.

![Get User Entitlements Configuration](img/image-4.png)

**Configuration:**
1. ✅ Check **Enabled**
2. Select **Stored Procedure**
3. Enter stored procedure call:
   ```sql
   CALL GET_USER_ENTITLEMENT(?)
   ```
4. **Parameter 1:**
   - Type: `DATABASE_FIELD`
   - Field Value: `USER_ID`

**What it does:** Queries the USERENTITLEMENTS table to retrieve all entitlements for a user with JOIN to USERS and ENTITLEMENTS tables.

---

### Provisioning Operations (To App)

These operations provision changes from Okta to your database.

#### Navigate to Provisioning Settings

1. Stay in the **Provisioning** tab
2. Go to **Integration** → **To App**
3. Click **Edit** next to **Provisioning**

---

#### 5. Create User

Create a new user in the database when assigned in Okta.

![Create User Configuration](img/image-5.png)

**Configuration:**
1. ✅ Check **Enabled**
2. Select **Stored Procedure**
3. Enter stored procedure call:
   ```sql
   CALL CREATE_USER(?, ?, ?, ?, ?, ?, ?)
   ```
4. **Map Parameters to Fields:**
   - Parameter 1: `DATABASE_FIELD` → `USER_ID`
   - Parameter 2: `DATABASE_FIELD` → `USERNAME`
   - Parameter 3: `DATABASE_FIELD` → `FIRSTNAME`
   - Parameter 4: `DATABASE_FIELD` → `LASTNAME`
   - Parameter 5: `DATABASE_FIELD` → `EMAIL`
   - Parameter 6: `DATABASE_FIELD` → `MANAGER`
   - Parameter 7: `DATABASE_FIELD` → `TITLE`

**What it does:** Inserts a new row into the USERS table with all user attributes.

---

#### 6. Update User

Update existing user attributes in the database.

![Update User Configuration](img/image-6.png)

**Configuration:**
1. ✅ Check **Enabled**
2. Select **Stored Procedure**
3. Enter stored procedure call:
   ```sql
   CALL UPDATE_USER(?, ?, ?, ?, ?, ?, ?)
   ```
4. **Map Parameters to Fields:**
   - Parameter 1: `DATABASE_FIELD` → `USER_ID`
   - Parameter 2: `DATABASE_FIELD` → `USERNAME`
   - Parameter 3: `DATABASE_FIELD` → `FIRSTNAME`
   - Parameter 4: `DATABASE_FIELD` → `LASTNAME`
   - Parameter 5: `DATABASE_FIELD` → `EMAIL`
   - Parameter 6: `DATABASE_FIELD` → `MANAGER`
   - Parameter 7: `DATABASE_FIELD` → `TITLE`

**What it does:** Updates the USERS table record matching the USER_ID with new attribute values.

---

#### 7. Activate User

Activate a user account (set IS_ACTIVE = 1).

![Activate User Configuration](img/image-7.png)

**Configuration:**
1. ✅ Check **Enabled**
2. Select **Stored Procedure**
3. Enter stored procedure call:
   ```sql
   CALL ACTIVATE_USER(?)
   ```
4. **Parameter 1:**
   - Type: `DATABASE_FIELD`
   - Field Value: `USER_ID`

**What it does:** Sets `IS_ACTIVE = TRUE` for the specified user in the USERS table.

---

#### 8. Deactivate User

Deactivate a user account (set IS_ACTIVE = 0).

![Deactivate User Configuration](img/image-8.png)

**Configuration:**
1. ✅ Check **Enabled**
2. Select **Stored Procedure**
3. Enter stored procedure call:
   ```sql
   CALL DEACTIVATE_USER(?)
   ```
4. **Parameter 1:**
   - Type: `DATABASE_FIELD`
   - Field Value: `USER_ID`

**What it does:** Sets `IS_ACTIVE = FALSE` for the specified user in the USERS table.

---

#### 9. Add Entitlement to User

Assign an entitlement to a user.

![Add Entitlement to User Configuration](img/image-9.png) 

**Configuration:**
1. ✅ Check **Enabled**
2. Select **Stored Procedure**
3. Enter stored procedure call:
   ```sql
   CALL ADD_ENTITLEMENT_TO_USER(?, ?)
   ```
4. **Map Parameters to Fields:**
   - Parameter 1: `DATABASE_FIELD` → `USER_ID`
   - Parameter 2: `DATABASE_FIELD` → `ENT_ID`

**What it does:** Inserts a new row into the USERENTITLEMENTS table, creating a user-entitlement mapping.

---

#### 10. Remove Entitlement from User

Revoke an entitlement from a user.

![Remove Entitlement from User Configuration](img/image-10.png)

**Configuration:**
1. ✅ Check **Enabled**
2. Select **Stored Procedure**
3. Enter stored procedure call:
   ```sql
   CALL REMOVE_ENTITLEMENT_FROM_USER(?, ?)
   ```
4. **Map Parameters to Fields:**
   - Parameter 1: `DATABASE_FIELD` → `USER_ID`
   - Parameter 2: `DATABASE_FIELD` → `ENT_ID`

**What it does:** Deletes the row from the USERENTITLEMENTS table matching the user and entitlement.

---

## Configure User Lifecycle Management

The Generic Database Connector application provides a set of features to maintain a healthy user lifecycle between Okta and your database. This section explores the options available to configure and streamline provisioning.

### Add Custom Attributes to Application User Profile

Before enabling provisioning configurations, you need to update the attributes for the Generic Database Connector application profile and their mapping to the Okta User profile. Since this application will be importing users with custom attributes into Okta, you need to add those attributes to the application user profile.

> **Note**: For more details on Okta User and Application User profiles, refer to [The Okta User Profile And Application User Profile](https://support.okta.com/help/s/article/The-Okta-User-Profile-And-Application-User-Profile?language=en_US).

**Steps to Add Attributes:**

1. **Navigate to Profile Editor**
   - In Okta Admin Console, go to **Directory** → **Profile Editor**

2. **Select Generic Database Connector User Profile**
   - Search for **"Generic Database Connector"**
   - Select the profile named **"Generic Database Connector User"**

   ![Profile Editor](img/profile-editor-1.png)

3. **Add Attributes from Database**
   - Under **Attributes**, you'll see that only the **Username** attribute is present
   - Click **+ Add Attribute**

   ![Add Attribute](img/profile-editor-2.png)

4. **Import Database Attributes**
   - The next page displays all attributes imported from the database
   - Check all the required attributes:
     - `ext_USER_ID`
     - `ext_FIRSTNAME`
     - `ext_LASTNAME`
     - `ext_EMAIL`
     - `ext_MANAGER`
     - `ext_TITLE`
     - And any other custom attributes
   - Click **Save**

   ![Select Attributes](img/profile-editor-3.png)

5. **Verify Attributes**
   - The Generic Database Connector user profile now contains all attributes needed for provisioning operations

### Mapping User Attributes

Attribute mapping must be configured for both directions:
- **Generic Database Connector User → Okta User** (for imports)
- **Okta User → Generic Database Connector User** (for provisioning)

#### Generic Database Connector User to Okta User

This mapping governs how user accounts from the database are imported into Okta.

**Configuration Steps:**

1. **Navigate to Mappings**
   - Within the **Generic Database Connector User** profile, click **Mappings**

   ![Navigate to Mappings](img/mapping-1.png)

2. **Configure Import Mappings**
   - By default, **Generic Database Connector User to Okta User** is selected
   - You'll see that mapping for `login` is present, but others are empty
   - Set up mappings for additional attributes as needed

   ![Default Mappings](img/mapping-2.png)

3. **Map Attributes**
   - Under **Okta User Profile**, click the dropdown in **Choose an attribute or enter an expression**
   - Select the corresponding attribute from **Generic Database Connector User Profile**

   Example mappings:
   - `firstName` ← `ext_FIRSTNAME`
   - `lastName` ← `ext_LASTNAME`
   - `email` ← `ext_EMAIL`
   - `title` ← `ext_TITLE`
   - `managerId` ← `ext_MANAGER`

   ![Configure Mappings](img/mapping-3.png)

4. **Save Mappings**
   - Click **Save**
   - Click **Apply updates**

#### Okta User to Generic Database Connector User

This mapping dictates how user attributes in Okta correlate with the database user profile, facilitating user creation or modification in the database.

**Configuration Steps:**

1. **Navigate to Mappings**
   - Within the **Generic Database Connector User** profile, click **Mappings**

2. **Select Okta User to Generic Database Connector User**
   - Click **Okta User to Generic Database Connector User**

   ![Okta to App Mapping](img/mapping-4.png)

3. **Map Attributes**
   - Click the dropdown under **Choose an attribute or enter an expression**
   - Select the appropriate attributes from **Okta User Profile**

   Example mappings:
   - `ext_USER_ID` ← `login`
   - `ext_USERNAME` ← `login`
   - `ext_FIRSTNAME` ← `firstName`
   - `ext_LASTNAME` ← `lastName`
   - `ext_EMAIL` ← `email`
   - `ext_MANAGER` ← `managerId`
   - `ext_TITLE` ← `title`

   ![Configure Okta to App Mappings](img/mapping-5.png)

4. **Save Mappings**
   - Click **Save**
   - Click **Apply updates**

### Import & Provisioning

Now that profile mappings are configured, you can enable import and provisioning features.

#### Setup Provisioning to Database

1. **Navigate to Provisioning Settings**
   - In Okta Admin Console, go to **Applications** → **Generic Database Connector**
   - Click the **Provisioning** tab
   - Navigate to **Settings** → **To App**

   ![Provisioning to App](img/provisioning-setup-1.png)

2. **Edit Provisioning Settings**
   - Click **Edit** in the **Provisioning to App** section

3. **Enable Provisioning Features**
   - ✅ **Create Users**: Enable to create users in the database when assigned in Okta
   - ✅ **Update User Attributes**: Enable to sync attribute changes from Okta to database
   - ✅ **Deactivate Users**: Enable to deactivate users in database when unassigned from Okta

   ![Enable Features](img/provisioning-setup-2.png)

4. **Save Configuration**
   - Click **Save**

#### Setup Import from Database

The Generic Database Connector provides functionality to import users from the database into Okta.

**Configuration Steps:**

1. **Navigate to Import Settings**
   - Go to **Applications** → **Generic Database Connector**
   - Click **Provisioning** tab
   - Navigate to **Settings** → **To Okta**
   - Click **Edit** next to **General**

   ![Import Settings](img/import-setup-1.png)

2. **Configure Import Schedule**
   - Under **Full Import Schedule**, select the desired frequency:
     - Every hour
     - Every 2 hours
     - Every 4 hours
     - Daily
     - Weekly
     - Manual (no automatic imports)

3. **Configure Okta Username Format**
   - Under **Okta username format**, select **Custom** from the dropdown
   - Enter: `appuser.ext_EMAIL` in the textbox
   - This ensures usernames are in email format using the `ext_EMAIL` attribute

   ![Username Format](img/import-setup-2.png)

4. **Save Configuration**
   - Click **Save**

#### Execute Manual Import

After configuring import settings, you can manually import users from the database to test the integration.

**Steps:**

1. **Navigate to Import Tab**
   - Go to **Applications** → **Generic Database Connector**
   - Click the **Import** tab

2. **Start Import**
   - Click **Import Now**
   - Select **Full Import**
   - Click **Import**

   ![Start Import](img/import-execute-1.png)

3. **Review Import Results**
   - Once import completes, you'll see an **Import Success** message
   - Review the list of users imported from the database

   ![Import Results](img/import-execute-2.png)

4. **Confirm User Assignments**
   - By default, imported users require manual confirmation (configurable in Import Settings)
   - Select the users you want to import into Okta
   - Click **Confirm Assignments**
   - Click **Confirm** when prompted

   ![Confirm Assignments](img/import-execute-3.png)

5. **Verify Imported Users**
   - Navigate to the **Assignments** tab
   - Verify that imported users are now visible

   ![Verify Users](img/import-execute-4.png)

## Testing

Now that the Generic Database Connector application is integrated and configured, you can test its capabilities.

### Test Case 1: Manual User Assignment

In this test, an Okta Administrator assigns a user to the Generic Database Connector application and grants entitlements. The user should be created in the database with the assigned entitlements reflected.

**Steps:**

1. **Assign User to Application**
   - Log on to **Okta Admin Console**
   - Navigate to **Applications** → **Generic Database Connector**
   - Click the **Assignments** tab
   - Click **Assign** → **Assign to People**

   ![Assign User](img/test-assign-1.png)

2. **Select User**
   - Search for a user (e.g., `testuser@example.com`)
   - Click **Assign** next to the user

3. **Review User Details**
   - The application auto-populates custom attribute values based on your mappings
   - Review and adjust values as needed
   - Empty fields can be manually entered

   ![Review Details](img/test-assign-2.png)

4. **Assign Entitlements**
   - Click **Assign and Continue** or **Save and Go Back**
   - In the **Entitlement Assignment** section, click **Edit Assignments**
   - Select **Custom Values** from the dropdown
   - Under **Entitlements**, select desired entitlements (e.g., "VPN Access", "GitHub Admin")
   - Click **Save**

   ![Assign Entitlements](img/test-assign-3.png)

5. **Verify in Okta**
   - The user should now appear under the **Assignments** tab
   - Click the menu button (three vertical dots) next to the user
   - Select **View access details** to see assigned entitlements

   ![View Access Details](img/test-assign-4.png)

6. **Verify in Database**
   - Check that the user was created in the database:
     ```bash
     docker compose exec db mysql -u oktademo -poktademo oktademo -e "SELECT * FROM USERS WHERE EMAIL='testuser@example.com';"
     ```

7. **Verify Entitlements in Database**
   - Check that entitlements were assigned:
     ```bash
     docker compose exec db mysql -u oktademo -poktademo oktademo -e "CALL GET_USER_ENTITLEMENT('testuser@example.com');"
     ```

   Expected output should show the user with assigned entitlements.

### Test Case 2: User Attribute Update

Test that attribute changes in Okta are synchronized to the database.

**Steps:**

1. **Update User in Okta**
   - Navigate to **Directory** → **People**
   - Find and select the user
   - Click **Profile** → **Edit**
   - Change an attribute (e.g., `title`, `department`)
   - Click **Save**

2. **Trigger Push to Application**
   - Navigate to **Applications** → **Generic Database Connector** → **Assignments**
   - Find the user and click the menu button
   - Select **Push now** (if available) or wait for automatic sync

3. **Verify in Database**
   - Check that changes were synced:
     ```bash
     docker compose exec db mysql -u oktademo -poktademo oktademo \
       -e "SELECT USER_ID, TITLE, EMAIL FROM USERS WHERE EMAIL='testuser@example.com';"
     ```

### Test Case 3: User Deactivation

Test that unassigning a user from the application deactivates them in the database.

**Steps:**

1. **Unassign User**
   - Navigate to **Applications** → **Generic Database Connector** → **Assignments**
   - Find the user and click the menu button
   - Select **Unassign**
   - Confirm the action

2. **Verify Deactivation in Database**
   - Check that the user's `IS_ACTIVE` flag is set to `0`:
     ```bash
     docker compose exec db mysql -u oktademo -poktademo oktademo \
       -e "SELECT USER_ID, EMAIL, IS_ACTIVE FROM USERS WHERE EMAIL='testuser@example.com';"
     ```

   Expected output: `IS_ACTIVE = 0`

### Test Case 4: Import Users from Database

Test importing existing users from the database into Okta.

**Steps:**

1. **Add Test User to Database**
   - Create a test user directly in the database:
     ```bash
     docker compose exec db mysql -u oktademo -poktademo oktademo -e \
       "CALL CREATE_USER('test.import@galaxy.local', 'test.import', 'Test', 'Import', 'test.import@galaxy.local', NULL, 'Test User');"
     ```

2. **Run Import**
   - Navigate to **Applications** → **Generic Database Connector** → **Import**
   - Click **Import Now** → **Full Import** → **Import**

3. **Confirm Import**
   - Review imported users
   - Select the new test user
   - Click **Confirm Assignments** → **Confirm**

4. **Verify in Okta**
   - Navigate to **Directory** → **People**
   - Search for `test.import@galaxy.local`
   - Verify the user was imported with correct attributes

### Monitor Logs

Check logs for any errors:
```bash
# SCIM Server logs
tail -f ./data/okta-scim/logs/*.log

# OPP Agent logs
tail -f ./data/okta-opp/logs/agent.log
```

## Troubleshooting

### Common Issues

**Stored Procedure Not Found**
- Verify procedures are installed: `docker compose exec db mysql -u oktademo -poktademo oktademo -e "SHOW PROCEDURE STATUS WHERE Db='oktademo';"`
- Reinitialize database if needed (see README.md)

**Parameter Mismatch**
- Ensure parameter count matches the stored procedure definition
- Check parameter types (DATABASE_FIELD, CURSOR, etc.)
- Review `sql/stored_proc.sql` for exact signatures

**Connection Timeout**
- Verify SCIM server is running: `docker compose ps okta-scim`
- Check database connectivity: `docker compose exec okta-scim mysql -h db -u oktademo -poktademo oktademo -e "SELECT 1;"`

**Entitlement Operations Failing**
- Verify ENT_ID exists: `SELECT * FROM ENTITLEMENTS;`
- Check foreign key constraints
- Review USERENTITLEMENTS table structure

### Debug Mode

Enable debug logging in SCIM Server:
1. Edit `./data/okta-scim/conf/config-*.properties`
2. Add or modify:
   ```properties
   logging.level.com.okta=DEBUG
   logging.level.org.springframework.jdbc=DEBUG
   ```
3. Restart SCIM container: `docker compose restart okta-scim`

## Additional Resources

- [Generic Database Connector Documentation](https://help.okta.com/oie/en-us/content/topics/provisioning/opc/connectors/on-prem-connector-generic-db.htm)
- [Stored Procedures Source](../sql/stored_proc.sql)
- [Database Schema](../sql/init.sql)
- [Project README](../README.md)
- [Quick Start Guide](../QUICKSTART.md)

---

**Note**: This configuration is designed for the lab environment. For production deployments, review and adjust stored procedures according to your security and compliance requirements.
