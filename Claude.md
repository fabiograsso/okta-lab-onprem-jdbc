# Claude.md - Project Documentation for AI Assistants

## Project Overview

This is a Docker-based lab environment for **Okta On-Premises Provisioning (OPP) Agent** with JDBC connectivity. It provides a containerized setup for testing and developing Okta provisioning integrations with on-premises databases.

**Project Name:** okta-lab-onprem-jdbc
**Author:** Fabio Grasso <fabio.grasso@okta.com>
**Purpose:** Laboratory environment for Okta OPP Agent with database connectivity testing

**Quick Start:** See [QUICKSTART.md](QUICKSTART.md) for fast setup instructions.

## Architecture

The project consists of four Docker services with separated OPP Agent and SCIM Server containers:

### 1. MariaDB Database (`db`)
- Image: `mariadb:11-alpine`
- Purpose: Local database for testing JDBC connectivity
- Port: 3306 (internal)
- Data persistence: `./data/mysql`
- SQL initialization: `./sql/` directory mounted to `/docker-entrypoint-initdb.d/`
- Health checks: Enabled with mariadb-admin ping

### 2. DBGate (`dbgate`)
- Image: `dbgate/dbgate:latest`
- Purpose: Web-based database management interface
- Port: 8090 (host) → 3000 (container)
- Access: http://localhost:8090
- Pre-configured connection to MariaDB
- Depends on: `db` service health

### 3. Okta OPP Agent (`okta-opp`)
- Base Image: `centos:stream9-minimal`
- Platform: `linux/amd64` (for macOS compatibility)
- Build context: `./docker/okta-opp/`
- Hostname: `okta-opp`
- Components:
  - Okta Provisioning Agent
  - Oracle JDK (bundled with agent)
- Volumes:
  - `./data/okta-opp/conf` → `/opt/OktaProvisioningAgent/conf/`
  - `./data/okta-opp/logs` → `/opt/OktaProvisioningAgent/logs/`
  - `./data/okta-opp/security` → `/opt/OktaProvisioningAgent/security/`
  - `./docker/okta-opp/packages` → `/packages` (read-only)
- Depends on: `db` service health

### 4. Okta SCIM Server (`okta-scim`)
- Base Image: `centos:stream9-minimal`
- Platform: `linux/amd64` (for macOS compatibility)
- Build context: `./docker/okta-scim/`
- Hostname: `okta-scim`
- Components:
  - Okta On-Prem SCIM Server
  - Oracle JDK (bundled with SCIM server)
  - Custom JDBC drivers (in userlib)
- Volumes:
  - `./data/okta-scim/logs` → `/var/log/OktaOnPremScimServer/`
  - `./data/okta-scim/conf` → `/etc/OktaOnPremScimServer/`
  - `./data/okta-scim/certs` → `/opt/OktaOnPremScimServer/certs/`
  - `./docker/okta-scim/packages` → `/packages` (read-only)
- Depends on: `db` service health

## Directory Structure

```
.
├── .env                          # Environment variables (gitignored)
├── .env-sample                   # Sample environment configuration
├── docker-compose.yml            # Docker services definition
├── Makefile                      # Build and deployment commands
├── README.md                     # User-facing documentation
├── CLAUDE.md                     # This file (AI assistant documentation)
├── CHANGELOG.md                  # Version history and changes
├── SECURITY.md                   # Security policy
├── data/                         # Persistent data (gitignored)
│   ├── mysql/                    # MariaDB data files
│   ├── okta-opp/                 # OPP Agent data
│   │   ├── conf/                 # Agent configuration files
│   │   ├── logs/                 # Agent logs
│   │   └── security/             # Keystores and certificates
│   └── okta-scim/                # SCIM Server data
│       ├── conf/                 # SCIM Server configuration
│       ├── logs/                 # SCIM Server logs
│       └── certs/                # SCIM Server certificates and keystores
├── docker/                       # Docker build contexts
│   ├── okta-opp/                 # OPP Agent container
│   │   ├── Dockerfile            # OPP Agent image definition
│   │   ├── entrypoint.sh         # OPP Agent startup script
│   │   └── packages/             # OPP Agent packages (not in git)
│   │       ├── OktaProvisioningAgent*.rpm
│   │       └── *.pem/*.crt       # Optional certificates
│   └── okta-scim/                # SCIM Server container
│       ├── Dockerfile            # SCIM Server image definition
│       ├── entrypoint.sh         # SCIM Server startup script
│       └── packages/             # SCIM Server packages (not in git)
│           ├── OktaOnPremScimServer*.rpm
│           ├── *.jar             # JDBC drivers
│           └── *.pem/*.crt       # Optional certificates
└── sql/                          # Database initialization scripts
    ├── init.sql                  # Schema and test data
    └── stored_proc.sql           # SCIM stored procedures
```

## Required Files (Not in Repository)

Before building, you must provide these files in separate directories for each container:

### OPP Agent Files (`./docker/okta-opp/packages/`):

1. **OPP Agent RPM**: `OktaProvisioningAgent-<version>.rpm`
   - **Required**: Yes
   - Download from: https://help.okta.com/oie/en-us/content/topics/provisioning/opp/opp-install-agent.htm
   - Example: `OktaProvisioningAgent-03.00.06-5d254f0.x86_64.rpm`

2. **CA Certificates**: `*.pem` or `*.crt` files
   - **Required**: No (optional)
   - Used for: HTTPS trust with custom VPN (e.g., Prisma Access, GlobalProtect)
   - Example: `myvpn.pem`
   - **Note**: Container will work without this but may not connect through custom VPN

### SCIM Server Files (`./docker/okta-scim/packages/`):

1. **SCIM Server RPM**: `OktaOnPremScimServer-<version>.rpm`
   - **Required**: Yes
   - Download from: https://help.okta.com/oie/en-us/content/topics/provisioning/opp/on-prem-scim-install.htm
   - Example: `OktaOnPremScimServer-1.5.0-1765324800.ef8fae9.rpm`

2. **JDBC Drivers**: `*.jar` files
   - **Required**: Yes
   - Generic JDBC connector info: https://help.okta.com/oie/en-us/content/topics/provisioning/opc/connectors/on-prem-connector-generic-db.htm
   - Examples:
     - MySQL Connector/J: `mysql-connector-j-9.6.0.jar` (primary for MariaDB)
     - MySQL Connector/J (legacy): `mysql-connector-java-*.jar`
     - MariaDB Connector/J: `mariadb-java-client-*.jar` (alternative)
     - PostgreSQL: `postgresql-*.jar`
   - Placed in: `/opt/OktaOnPremScimServer/userlib/` during container startup
   - Download MySQL Connector/J from: https://dev.mysql.com/downloads/connector/j/ (select 'Platform Independent' to get the .jar file)

3. **CA Certificates**: `*.pem` or `*.crt` files
   - **Required**: No (optional)
   - Used for: HTTPS trust with custom VPN
   - Example: `myvpn.pem`
   - **Note**: Container will work without this but may not connect through custom VPN

## Database Initialization

The MariaDB container automatically executes SQL scripts from `./sql/` directory on first startup (via Docker's `/docker-entrypoint-initdb.d/` mechanism).

### Schema and Test Data (`sql/init.sql`)

Creates three core tables:

**USERS Table** (30 fields total):

**Identity Fields**:
- `USER_ID` VARCHAR(100) PRIMARY KEY - User identifier (email format) **(required)**
- `USERNAME` VARCHAR(100) UNIQUE NOT NULL - Login username (unique constraint enforced) **(required)**
- `EMAIL` VARCHAR(100) NOT NULL - Email address **(required)**

**Personal Information**:
- `FIRSTNAME` VARCHAR(100) - First name **(required)**
- `LASTNAME` VARCHAR(100) - Last name **(required)**
- `MIDDLENAME` VARCHAR(100) - Middle name (nullable)
- `HONORIFICPREFIX` VARCHAR(50) - Honorific prefix (Mr., Ms., Dr., etc.) (nullable)
- `DISPLAYNAME` VARCHAR(200) - Display name for UI (nullable)
- `NICKNAME` VARCHAR(100) - Nickname or preferred name (nullable)
- `BIRTHDATE` DATE - Date of birth (nullable)

**Contact Information**:
- `MOBILEPHONE` VARCHAR(50) - Mobile phone number (nullable)
- `STREETADDRESS` VARCHAR(200) - Street address (nullable)
- `CITY` VARCHAR(100) - City (nullable)
- `STATE` VARCHAR(100) - State or province (nullable)
- `ZIPCODE` VARCHAR(20) - ZIP or postal code (nullable)
- `COUNTRYCODE` VARCHAR(10) - Country code (nullable)
- `POSTALADDRESS` VARCHAR(500) - Full postal address (nullable)
- `TIMEZONE` VARCHAR(100) - User's timezone (nullable)
- `EMERGENCYCONTACT` VARCHAR(200) - Emergency contact information (nullable)

**Work Information**:
- `TITLE` VARCHAR(100) - Title (nullable)
- `DEPARTMENT` VARCHAR(100) - Department (nullable)
- `EMPLOYEENUMBER` VARCHAR(50) - Employee number (nullable)
- `MANAGER` VARCHAR(100) - Manager's USER_ID (nullable)
- `MANAGERID` VARCHAR(100) - Manager ID (nullable)
- `WORKLOCATION` VARCHAR(200) - Work location (nullable)
- `COSTCENTER` VARCHAR(100) - Cost center (nullable)

**Employment Dates**:
- `HIREDATE` DATE - Date of hire (nullable)
- `TERMINATIONDATE` DATE - Date of termination (nullable)

**Security**:
- `PASSWORD_HASH` VARCHAR(255) - Password hash (nullable)
- `IS_ACTIVE` BOOLEAN - Account status (default TRUE)

**Mandatory Fields**: Only USER_ID, USERNAME, FIRSTNAME, LASTNAME, and EMAIL are required. All other 25 fields are optional and can be NULL.

**ENTITLEMENTS Table**:
- `ENT_ID` INT PRIMARY KEY - Entitlement identifier (manually specified values 1-10)
- `ENT_NAME` VARCHAR(100) UNIQUE - Entitlement name
- `ENT_DESCRIPTION` TEXT - Description of the entitlement

**USERENTITLEMENTS Table** (junction table):
- `USERENTITLEMENT_ID` INT PRIMARY KEY AUTO_INCREMENT
- `USER_ID` VARCHAR(100) - Foreign key to USERS
- `ENT_ID` INT - Foreign key to ENTITLEMENTS
- `ASSIGNEDDATE` DATETIME - When entitlement was assigned
- Unique constraint on (USER_ID, ENT_ID)

**Test Data**:
- **15 Star Wars characters** as test users from `2.users.ldif` (Luke Skywalker, Leia Organa, Han Solo, Obi-Wan Kenobi, Yoda, etc.)
  - Populated with extended profile data: displayName, department, postalAddress, employeeNumber, password hash, costCenter
  - Light Side: Jedi Council members and Resistance leaders
  - Dark Side: Imperial High Command
  - Droids: Protocol and Astromech units
- **10 entitlements**: VPN Access, GitHub Admin, AWS Console, Jira Admin, Confluence Edit, Database Read, Database Write, Slack Admin, Office 365, Salesforce
- **Realistic entitlement assignments** based on job roles:
  - Senior Developers: VPN, GitHub, AWS, Database Read/Write, Office 365
  - Engineering Managers: All entitlements including Jira Admin, Slack Admin
  - DevOps Engineers: VPN, GitHub, AWS, Database Read/Write
  - Product Managers: VPN, Jira, Confluence, Office 365, Salesforce

### Stored Procedures (`sql/stored_proc.sql`)

Based on Oracle examples from Appendix A of the Generic Database Connector documentation, adapted for MySQL/MariaDB:

1. **GET_ACTIVEUSERS()** - Returns all active users
   - Output: All 30 user fields (USER_ID, USERNAME, FIRSTNAME, LASTNAME, MIDDLENAME, HONORIFICPREFIX, EMAIL, DISPLAYNAME, NICKNAME, MOBILEPHONE, STREETADDRESS, CITY, STATE, ZIPCODE, COUNTRYCODE, POSTALADDRESS, TIMEZONE, DEPARTMENT, MANAGERID, WORKLOCATION, EMERGENCYCONTACT, PASSWORD_HASH, IS_ACTIVE, COSTCENTER, MANAGER, TITLE, HIREDATE, TERMINATIONDATE, BIRTHDATE, EMPLOYEENUMBER)

2. **GET_ALL_ENTITLEMENTS()** - Returns all available entitlements
   - Output: ENT_ID, ENT_NAME, ENT_DESCRIPTION

3. **GET_USER_BY_ID(p_user_id)** - Returns specific user details
   - Input: p_user_id VARCHAR(100)
   - Output: All 30 user fields (same as GET_ACTIVEUSERS)

4. **GET_USER_ENTITLEMENT(p_user_id)** - Returns user's entitlements with details
   - Input: p_user_id VARCHAR(100)
   - Output: USERENTITLEMENT_ID, USER_ID, USERNAME, EMAIL, ENT_ID, ENT_NAME, ENT_DESCRIPTION, ASSIGNEDDATE

5. **CREATE_USER(...)** - Creates a new user account
   - **29 Parameters** (5 mandatory + 24 optional):
     - **Mandatory**: p_user_id, p_username, p_firstname, p_lastname, p_email
     - **Optional**: p_middlename, p_honorificprefix, p_displayname, p_nickname, p_mobilephone, p_streetaddress, p_city, p_state, p_zipcode, p_countrycode, p_postaladdress, p_timezone, p_department, p_managerid, p_worklocation, p_emergencycontact, p_password_hash, p_costcenter, p_manager, p_title, p_hiredate, p_terminationdate, p_birthdate, p_employeenumber
   - Sets IS_ACTIVE = 1 by default
   - All optional parameters can be NULL

6. **UPDATE_USER(...)** - Updates existing user attributes
   - **29 Parameters** (5 mandatory + 24 optional):
     - **Mandatory**: p_user_id, p_username, p_firstname, p_lastname, p_email
     - **Optional**: Same 24 optional parameters as CREATE_USER
   - Updates all fields based on USER_ID
   - All optional parameters can be NULL

7. **ACTIVATE_USER(p_user_id)** - Sets user status to active
   - Input: p_user_id VARCHAR(100)
   - Sets IS_ACTIVE = 1

8. **DEACTIVATE_USER(p_user_id)** - Sets user status to inactive
   - Input: p_user_id VARCHAR(100)
   - Sets IS_ACTIVE = 0

9. **ADD_ENTITLEMENT_TO_USER(p_user_id, p_ent_id)** - Assigns entitlement to user
   - Inputs: p_user_id VARCHAR(100), p_ent_id INT
   - Inserts into USERENTITLEMENTS with current timestamp
   - Uses unique constraint to prevent duplicates

10. **REMOVE_ENTITLEMENT_FROM_USER(p_user_id, p_ent_id)** - Revokes entitlement from user
    - Inputs: p_user_id VARCHAR(100), p_ent_id INT
    - Deletes from USERENTITLEMENTS

These procedures can be referenced in the Generic Database Connector configuration in Okta for SCIM operations.

**See also**:
- [doc/Okta_Provisioning_Configuration.md](doc/Okta%20Provisioning%20Configuration.md) for detailed step-by-step configuration instructions in the Okta Admin Console.
- [doc/Okta_SCIM_Server.md](doc/Okta_SCIM_Server.md) for technical details about the SCIM Server's internal architecture and API endpoints.

## Configuration

### Environment Variables (.env)

```bash
MARIADB_PORT=3306
MARIADB_ROOT_PASSWORD=oktademo
MARIADB_USER=oktademo
MARIADB_PASSWORD=oktademo
MARIADB_DATABASE=oktademo
```

### OPP Agent Configuration

The agent waits for configuration files before starting. Required files in `./data/okta-opp/conf/`:

1. **OktaProvisioningAgent.conf** - Must contain:
   - `orgUrl` - Your Okta org URL
   - `agentId` - Agent identifier
   - `keystoreKey` - Keystore encryption key
   - `keyPassword` - Key password
   - `env` - Environment (preview/prod)
   - `subdomain` - Okta subdomain
   - `agentKey` - Agent authentication key

2. **settings.conf** - Java options (auto-configured by entrypoint):
   - `JAVA_OPTS="-Xmx4096m -Dhttps.protocols=TLSv1.2"`

3. **Keystore**: `./data/okta-opp/security/OktaProvisioningKeystore.p12`

The entrypoint script creates these files if they don't exist and waits for proper configuration before starting the agent.

### SCIM Server Configuration

Configuration files are automatically generated and stored in `./data/okta-scim/`:

**Auto-generated files**:
- **Spring Boot Properties**: `/etc/OktaOnPremScimServer/config-${CUSTOMER_ID}.properties`
  - Contains SCIM server configuration including `scim.security.bearer.token`
  - Synced to: `./data/okta-scim/conf/config-*.properties`

- **Customer ID Config**: `/etc/OktaOnPremScimServer/customer-id.conf`
  - Contains `CUSTOMER_ID` environment variable

- **JVM Configuration**: `/etc/OktaOnPremScimServer/jvm.conf`
  - Contains Java memory and GC settings

**Certificates and Keystores** (auto-generated on first startup):
- **Public Certificate**: `/opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-${CUSTOMER_ID}.crt`
  - 4096-bit RSA, 10-year validity, self-signed
  - Synced to: `./data/okta-scim/certs/OktaOnPremScimServer-*.crt`

- **Private Key**: `/opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-${CUSTOMER_ID}.key`
  - RSA private key in PEM format
  - Synced to: `./data/okta-scim/certs/OktaOnPremScimServer-*.key`

- **PKCS12 Keystore**: `/opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-${CUSTOMER_ID}.p12`
  - Contains certificate and private key
  - Synced to: `./data/okta-scim/certs/OktaOnPremScimServer-*.p12`

**Logs**:
- Location: `/var/log/OktaOnPremScimServer/`
- Synced to: `./data/okta-scim/logs/`

**IMPORTANT**: When configuring the Generic Database Connector in Okta Admin Console, the bearer token **MUST** include the `Bearer ` prefix:
```
Bearer <token-value-from-properties-file>
```

## Build and Deployment Commands (Makefile)

The Makefile includes prerequisite checks and various deployment options:

```bash
make help            # Display all available commands with descriptions
make check-prereqs   # Run prerequisite checks without starting services
make build           # Build Docker images (with prereq checks)
make rebuild         # Force rebuild from scratch (no cache, pull latest)
make start           # Check prereqs and start services in detached mode
make start-live      # Check prereqs and start services in foreground (live logs)
make start-logs      # Check prereqs, start detached, and follow logs
make stop            # Stop and remove all containers
make restart         # Stop then start services
make restart-logs    # Restart and follow logs
make logs            # Follow container logs (last 500 lines)
make kill            # Kill containers and remove orphans
make configure       # Launch interactive Okta agent configuration script
```

### Prerequisite Checks (check-prereqs)

The `check-prereqs` target automatically runs before `start`, `start-live`, `start-logs`, and `build` commands. It verifies:

1. **Okta Provisioning Agent RPM**:
   - Checks for: `./docker/okta-opp/packages/OktaProvisioningAgent-*.rpm`
   - Error if missing with download link

2. **Okta SCIM Server RPM**:
   - Checks for: `./docker/okta-scim/packages/OktaOnPremScimServer-*.rpm`
   - Error if missing with download link

3. **JDBC Driver JAR Files**:
   - Checks for: `./docker/okta-scim/packages/*.jar`
   - Error if missing with examples

4. **Certificate Files** (optional):
   - Checks for: `./docker/okta-opp/packages/*.pem` and `./docker/okta-scim/packages/*.pem`
   - Also checks for: `*.crt` files
   - **Warning only** (non-blocking) - containers work without custom certificates but may not work with custom VPN

5. **.env File Existence**:
   - Checks for: `./.env`
   - Error if missing with copy command

6. **Required Environment Variables**:
   - `MARIADB_DATABASE` - Database name
   - `MARIADB_USER` - Database user
   - `MARIADB_PASSWORD` - Database password
   - `MARIADB_ROOT_PASSWORD` - Database root password
   - Error if any variable is empty

The checks will exit with error code 1 if any critical prerequisite fails. Only certificates are optional (warning only).

### Interactive Configuration (configure)

The Makefile includes a `configure` target to run the interactive Okta agent configuration script:

```bash
make configure
```

This executes: `docker compose exec okta-opp /opt/OktaProvisioningAgent/configure_agent.sh`

**Requirements**:
- Container must be running: `make start` first
- Configuration script must exist in the container at `/opt/OktaProvisioningAgent/configure_agent.sh`

**Alternative**: Manually configure by placing configuration files in `./data/okta-opp/conf/` (see OPP Agent Configuration section).

## Setup Workflow

1. **Prepare package files**:
   ```bash
   # Create package directories
   mkdir -p docker/okta-opp/packages
   mkdir -p docker/okta-scim/packages

   # Copy OPP Agent files to docker/okta-opp/packages/:
   # Required:
   # - OktaProvisioningAgent-*.rpm
   # Optional (warning only):
   # - Certificate files (*.pem or *.crt) - for custom VPN support

   # Copy SCIM Server files to docker/okta-scim/packages/:
   # Required:
   # - OktaOnPremScimServer-*.rpm
   # - JDBC driver JAR files (*.jar) - e.g., mysql-connector-j-9.6.0.jar
   # Optional (warning only):
   # - Certificate files (*.pem or *.crt) - for custom VPN support
   ```

2. **Configure environment**:
   ```bash
   cp .env-sample .env
   # Edit .env if needed (default values work for local testing)
   ```

3. **Build containers**:
   ```bash
   make build
   # Prerequisite checks will run automatically
   # Will fail if required RPMs or JDBC drivers are missing
   # Will show warnings (non-blocking) if certificates are missing
   ```

4. **Start services**:
   ```bash
   make start-logs
   # Starts all services and follows logs
   # Prerequisite checks will run automatically
   # Database will be initialized with test data from sql/ directory
   ```

5. **Configure OPP Agent**:
   - Wait for message in okta-opp logs: "⏳ Waiting for configuration files"
   - Option A: Run interactive configuration: `make configure`
   - Option B: Place configuration files manually in `./data/okta-opp/conf/`
   - Agent will auto-start when configuration is detected

6. **Retrieve SCIM Credentials**:
   After SCIM server starts, credentials are automatically displayed in logs. You can also retrieve them:
   ```bash
   # Option A: From host filesystem
   cat ./data/okta-scim/conf/config-*.properties | grep scim.security.bearer.token
   cat ./data/okta-scim/certs/OktaOnPremScimServer-*.crt

   # Option B: From container
   docker compose exec okta-scim /opt/OktaOnPremScimServer/bin/Get-OktaOnPremScimServer-Credentials.sh
   docker compose exec okta-scim 'cat /opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-*.crt'
   ```

   You'll need these for configuring the Okta application:
   - SCIM Hostname: `okta-scim` (hostname matches container name)
   - SCIM Bearer Token: `Bearer <token-value>` (must include "Bearer " prefix)
   - Public Certificate: Upload the .crt file

7. **Verify database initialization**:
   ```bash
   # Check that test data loaded
   docker compose exec db mariadb -u oktademo -poktademo oktademo -e "SELECT COUNT(*) FROM USERS;"
   # Should return 15 users

   # Test stored procedures
   docker compose exec db mariadb -u oktademo -poktademo oktademo -e "CALL GET_ACTIVEUSERS();"
   ```

8. **Access DBGate**:
   - URL: http://localhost:8090
   - Pre-configured connection to MariaDB (user: root, password from .env)

## Container Behavior

The project now uses **two separate containers** for better separation of concerns:

### OPP Agent Container (okta-opp) Entrypoint Flow

Location: `./docker/okta-opp/entrypoint.sh`

1. **Display Okta ASCII logo**: Visual confirmation of startup

2. **Update CA certificates** (if present):
   - Copies `*.pem` and `*.crt` files from `/packages/` to system trust store
   - Runs `update-ca-trust`
   - Shows warning if no certificates found (non-blocking)

3. **Create required directories and set permissions**:
   - `/opt/OktaProvisioningAgent/security`
   - `/opt/OktaProvisioningAgent/conf`
   - `/opt/OktaProvisioningAgent/logs`
   - Creates `settings.conf` and `agent.log` if not present

4. **Configure Java options**: Sets `-Xmx4096m` and `-Dhttps.protocols=TLSv1.2` in `settings.conf`

5. **Set ownership and permissions**:
   - Ownership to `provisioningagent:provisioningagent`
   - Makes JRE binaries executable

6. **Wait for required configuration files**:
   - Polls every 10 seconds
   - Checks for required keys in `OktaProvisioningAgent.conf`:
     - orgUrl, agentId, keystoreKey, keyPassword, env, subdomain, agentKey
   - Verifies keystore exists at `/opt/OktaProvisioningAgent/security/OktaProvisioningKeystore.p12`
   - Displays "⏳ Waiting for configuration files" message until ready

7. **Start OPP Agent in background**:
   - Executes `/opt/OktaProvisioningAgent/OktaProvisioningAgent` as background process

8. **Tail agent log file**: Continuously displays `/opt/OktaProvisioningAgent/logs/agent.log` for monitoring

**Key Changes from Previous Version**:
- No longer starts SCIM Server (now in separate container)
- Certificate handling moved earlier in the flow (before config check)
- Simplified to focus only on OPP Agent concerns

### SCIM Server Container (okta-scim) Entrypoint Flow

Location: `./docker/okta-scim/entrypoint.sh`

1. **Display Okta ASCII logo**: Visual confirmation of startup

2. **Update CA certificates** (if present):
   - Copies `*.pem` and `*.crt` files from `/packages/` to system trust store
   - Runs `update-ca-trust`
   - Shows warning if no certificates found (non-blocking)

3. **Create certificate symlinks**:
   - Creates symlinks for certificate and private key directories
   - `/etc/pki/tls/certs/` and `/etc/pki/tls/private/`

4. **Generate CUSTOMER_ID** (if not exists):
   - Creates unique customer ID if not already configured
   - Saves to `/etc/OktaOnPremScimServer/customer-id.conf`

5. **Generate RSA key pair and certificate**:
   - Creates 4096-bit RSA private key
   - Generates self-signed certificate (10-year validity)
   - Creates PKCS12 keystore with random password
   - Saves to `/opt/OktaOnPremScimServer/certs/`

6. **Create Spring Boot configuration**:
   - Generates `config-${CUSTOMER_ID}.properties` with:
     - Server port (1443)
     - SSL/TLS configuration
     - Keystore location and password
     - Auto-generated API bearer token
     - Logging configuration

7. **Create JVM configuration**:
   - Sets memory limits and GC options
   - Saves to `/etc/OktaOnPremScimServer/jvm.conf`

8. **Copy JDBC drivers**:
   - Copies all `*.jar` files from `/packages/` to `/opt/OktaOnPremScimServer/userlib/`
   - Handles multiple drivers (MySQL Connector/J, MariaDB Connector/J, PostgreSQL, etc.)

9. **Display SCIM credentials**:
   - Runs `Get-OktaOnPremScimServer-Credentials.sh`
   - Shows SCIM Base URL, Bearer Token, and other configuration details
   - Makes credentials easily visible in container logs

10. **Start SCIM Server**:
    - Executes `/opt/OktaOnPremScimServer/bin/OktaOnPremScimServer.sh` in foreground
    - Server listens on port 1443 (HTTPS)

**Key Changes from Previous Version**:
- Standalone container, no dependency on OPP Agent
- Certificate handling moved to beginning of script
- Credentials displayed before server startup for better visibility
- All configuration auto-generated on first run
- Direct volume mounts (no sync function needed)

### Volume Mounts and File Persistence

**OPP Agent Volumes**:
- `./data/okta-opp/conf` → `/opt/OktaProvisioningAgent/conf/`
- `./data/okta-opp/logs` → `/opt/OktaProvisioningAgent/logs/`
- `./data/okta-opp/security` → `/opt/OktaProvisioningAgent/security/`
- `./docker/okta-opp/packages` → `/packages` (read-only)

**SCIM Server Volumes**:
- `./data/okta-scim/logs` → `/var/log/OktaOnPremScimServer/`
- `./data/okta-scim/conf` → `/etc/OktaOnPremScimServer/`
- `./data/okta-scim/certs` → `/opt/OktaOnPremScimServer/certs/`
- `./docker/okta-scim/packages` → `/packages` (read-only)

All configuration, certificates, and logs are persisted to the host filesystem and survive container restarts.

## Database Access

### Via DBGate UI
- URL: http://localhost:8090
- Connection: Pre-configured for MariaDB
- User: oktademo
- Password: oktademo

### Via Command Line
```bash
docker-compose exec db mariadb -u oktademo -poktademo oktademo
```

### Via JDBC (from OPP)
- Host: `db` (Docker network)
- Port: 3306
- Database: oktademo
- User: oktademo
- Password: oktademo

## Troubleshooting

### Check service status
```bash
docker-compose ps
```

### View logs
```bash
make logs                                    # All services
docker compose logs -f okta-opp              # OPP Agent only (shows tailed agent.log)
docker compose logs -f okta-scim             # SCIM Server only
docker compose logs -f db                    # Database only

# Access log files directly on host
tail -f ./data/okta-opp/logs/agent.log       # OPP Agent log
tail -f ./data/okta-scim/logs/*.log          # SCIM Server logs
```

**Log Locations**:
- OPP Agent: `./data/okta-opp/logs/agent.log`
- SCIM Server: `./data/okta-scim/logs/`
- MariaDB: Docker logs only (use `docker compose logs db`)

### Agent not starting
1. Verify configuration files exist in `./data/okta-opp/conf/`
2. Check for required keys in `OktaProvisioningAgent.conf`:
   - `orgUrl`
   - `agentId`
   - `keystoreKey`
   - `keyPassword`
   - `env`
   - `subdomain`
   - `agentKey`
3. Verify keystore exists in `./data/okta-opp/security/OktaProvisioningKeystore.p12`
4. Check directory permissions (should be owned by `provisioningagent` user inside container)
5. Check logs: `docker compose logs -f okta-opp`
6. Check agent log file directly: `tail -f ./data/okta-opp/logs/agent.log`

### SCIM Server issues
1. Check SCIM logs: `./data/okta-scim/logs/`
2. Verify JDBC drivers are in place: `./docker/okta-scim/packages/*.jar`
3. Check SCIM configuration: `./data/okta-scim/conf/`
4. Verify SCIM credentials in properties file:
   ```bash
   # From container
   docker compose exec okta-scim /opt/OktaOnPremScimServer/bin/Get-OktaOnPremScimServer-Credentials.sh

   # From host filesystem
   cat ./data/okta-scim/conf/config-*.properties | grep scim.security.bearer.token
   ```
5. Check SCIM Server is running:
   ```bash
   docker compose exec okta-scim ps aux | grep OktaOnPremScimServer
   ```
6. Test SCIM endpoint:
   ```bash
   # Replace YOUR_TOKEN with actual bearer token
   curl -i https://localhost:1443/ws/rest/jdbc_on_prem/scim/v2/ServiceProviderConfig \
     -H "Authorization: Bearer YOUR_TOKEN" \
     --insecure
   ```

### Database connection issues
1. Verify database is healthy: `docker-compose ps db`
2. Test connection: `docker-compose exec db mariadb-admin ping`
3. Check environment variables in `.env`

### Build failures
1. Verify package files exist:
   - OPP Agent: `ls -la docker/okta-opp/packages/`
   - SCIM Server: `ls -la docker/okta-scim/packages/`
2. Check Docker platform: Should be `linux/amd64`
3. Rebuild without cache: `make rebuild`

### Prerequisite check failures (make start/build)

If `make start` or `make build` fails with prerequisite errors:

1. **Missing RPM files**:
   - Ensure `OktaProvisioningAgent-*.rpm` is in `./docker/okta-opp/packages/`
   - Ensure `OktaOnPremScimServer-*.rpm` is in `./docker/okta-scim/packages/`
   - Download from Okta documentation links (see error message)

2. **Missing JDBC driver files**:
   - Ensure JDBC driver `*.jar` files are in `./docker/okta-scim/packages/`
   - Download MySQL Connector/J: https://dev.mysql.com/downloads/connector/j/ (select 'Platform Independent' to get the .jar file)
   - Or download appropriate driver for your database (PostgreSQL, etc.)

3. **Certificate file warning** (non-blocking):
   - This is just a warning and won't prevent build/start
   - Add `*.pem` or `*.crt` files if you need custom VPN support

4. **Missing .env file**:
   - Copy: `cp .env-sample .env`

5. **Empty environment variables**:
   - Edit `.env` file and ensure all `MARIADB_*` variables have values

### Configure command not working (make configure)

If `make configure` fails:

1. **Service not running**:
   - Start the service first: `make start`
   - Verify it's running: `docker compose ps okta-opp`

2. **Configuration script doesn't exist**:
   - Check if script exists: `docker compose exec okta-opp ls -la /opt/OktaProvisioningAgent/configure_agent.sh`
   - Use manual configuration instead (see OPP Agent Configuration section)

### Enabling Database Query Logging

To debug and monitor SQL queries executed by the Okta provisioning system, enable MariaDB's general query log to see all SQL statements received by the server.

#### Enable Query Logging (Temporary - Runtime)

Enable query logging for the current database session without restarting containers:

```bash
# Connect to database and enable general log
docker compose exec db mariadb -u root -p${MARIADB_ROOT_PASSWORD:-oktademo} -e "SET GLOBAL general_log = 'ON';"
docker compose exec db mariadb -u root -p${MARIADB_ROOT_PASSWORD:-oktademo} -e "SET GLOBAL general_log_file = '/var/log/mysql/general.log';"

# Verify logging is enabled
docker compose exec db mariadb -u root -p${MARIADB_ROOT_PASSWORD:-oktademo} -e "SHOW VARIABLES LIKE 'general_log%';"
```

This will enable logging until the container is restarted.

#### Enable Query Logging (Permanent)

To enable query logging permanently, modify the `docker-compose.yml` file to add command-line options to the MariaDB container:

```yaml
services:
  db:
    image: mariadb:11-alpine
    command:
      - --general-log=1
      - --general-log-file=/var/log/mysql/general.log
    # ... rest of configuration
```

After modifying `docker-compose.yml`, restart the database:

```bash
make restart
```

#### View Query Logs

**Real-time monitoring**:
```bash
# Follow the general query log in real-time
docker compose exec db tail -f /var/log/mysql/general.log
```

**View recent queries**:
```bash
# Show last 100 lines
docker compose exec db tail -n 100 /var/log/mysql/general.log

# Search for specific queries (e.g., stored procedures)
docker compose exec db grep "CALL" /var/log/mysql/general.log

# Search for CREATE_USER operations
docker compose exec db grep "CREATE_USER" /var/log/mysql/general.log

# Search for UPDATE_USER operations
docker compose exec db grep "UPDATE_USER" /var/log/mysql/general.log
```

#### Disable Query Logging

To disable query logging and reduce overhead:

```bash
docker compose exec db mariadb -u root -p${MARIADB_ROOT_PASSWORD:-oktademo} -e "SET GLOBAL general_log = 'OFF';"
```

#### Log File Location

- **Inside container**: `/var/log/mysql/general.log`
- **Note**: By default, this log file is NOT persisted to the host filesystem
- **To persist logs**: Add a volume mount in `docker-compose.yml`:

```yaml
services:
  db:
    # ... existing configuration
    volumes:
      - ./data/mysql:/var/lib/mysql
      - ./data/mysql-logs:/var/log/mysql  # Add this line
```

Then create the directory and restart:
```bash
mkdir -p ./data/mysql-logs
make restart
```

#### Performance Considerations

**Important**: The general query log can generate significant I/O and disk usage in production environments:

- **Log file growth**: All queries are logged, including SELECT statements
- **Performance impact**: Writing to the log file adds overhead to every query
- **Disk space**: Log files can grow rapidly with high query volume

**Best Practices**:
- Enable query logging only during debugging or testing
- Disable logging in production environments
- Monitor log file size: `docker compose exec db ls -lh /var/log/mysql/general.log`
- Rotate or clear logs periodically

#### Example Query Log Output

When provisioning operations occur, you'll see entries like:

```
2024-02-17T10:30:45.123456Z    42 Connect   oktademo@172.18.0.5 on oktademo using TCP/IP
2024-02-17T10:30:45.234567Z    42 Query     CALL CREATE_USER('john.doe@example.com', 'jdoe', 'John', 'Doe', 'john.doe@example.com', NULL, NULL, 'John Doe', NULL, '+1234567890', '123 Main St', 'New York', 'NY', '10001', 'US', NULL, 'America/New_York', 'Engineering', NULL, 'New York Office', NULL, NULL, 'ENG-001', NULL, 'Software Engineer', '2024-01-15', NULL, '1990-05-20', 'EMP-12345')
2024-02-17T10:30:45.456789Z    42 Query     CALL ADD_ENTITLEMENT_TO_USER('john.doe@example.com', 1)
2024-02-17T10:30:45.567890Z    42 Query     CALL ADD_ENTITLEMENT_TO_USER('john.doe@example.com', 2)
2024-02-17T10:30:45.678901Z    42 Quit
```

This shows the exact SQL statements being executed, including all parameter values, which is invaluable for debugging provisioning issues.

## Development Notes

### Modifying the OPP Agent Container

1. Edit `docker/okta-opp/Dockerfile` or `docker/okta-opp/entrypoint.sh`
2. Rebuild: `make rebuild`
3. Restart: `make restart-logs`

### Modifying the SCIM Server Container

1. Edit `docker/okta-scim/Dockerfile` or `docker/okta-scim/entrypoint.sh`
2. Rebuild: `make rebuild`
3. Restart: `make restart-logs`

### Adding JDBC Drivers

1. Place `.jar` files in `./docker/okta-scim/packages/`
2. Rebuild container: `make rebuild`
3. Verify installation:
   ```bash
   docker compose exec okta-scim ls -la /opt/OktaOnPremScimServer/userlib/
   ```

### Certificate Management

**OPP Agent**:
- Certificates are updated on each container start
- Source: `./docker/okta-opp/packages/*.pem` or `*.crt`
- Destination: `/etc/pki/ca-trust/source/anchors/`
- Auto-update via `update-ca-trust`

**SCIM Server**:
- Certificates are updated on each container start
- Source: `./docker/okta-scim/packages/*.pem` or `*.crt`
- Destination: `/etc/pki/ca-trust/source/anchors/`
- Auto-update via `update-ca-trust`

### Database Schema Changes

To modify the database schema or add new test data:

1. Edit `sql/init.sql` (schema and initial data)
2. Edit `sql/stored_proc.sql` (stored procedures)
3. Remove existing database data:
   ```bash
   docker compose down
   rm -rf ./data/mysql
   ```
4. Restart to reinitialize:
   ```bash
   make start-logs
   ```

Note: The SQL scripts only run on first database initialization. For existing databases, you'll need to apply changes manually.

## Security Considerations

- Default passwords are for lab use only
- `.env` file is gitignored (contains credentials)
- Keystores and certificates are gitignored
- OPP agent runs as `provisioningagent` user (non-root)

## Known Issues

### Platform Compatibility
- Container forced to `linux/amd64` for macOS compatibility
- May have performance implications on ARM Macs

### Port Conflicts
- DBGate uses port 8090
- MariaDB uses port 3306 (internal only)
- Check for conflicts: `lsof -i :8090`

## References

1. [Install the Okta Provisioning Agent](https://help.okta.com/oie/en-us/content/topics/provisioning/opp/opp-install-agent.htm)
2. [Install the Okta On-prem SCIM Server](https://help.okta.com/oie/en-us/content/topics/provisioning/opp/on-prem-scim-install.htm)
3. [On-premises Connector for Generic Databases](https://help.okta.com/oie/en-us/content/topics/provisioning/opc/connectors/on-prem-connector-generic-db.htm)

## Version Information

- MariaDB: 11 Alpine
- DBGate: Latest
- CentOS: Stream 9 Minimal
- Oracle JDK: 21.0.9
- OPP Agent: Version from RPM (varies)
- SCIM Server: Version from RPM (varies)

## Important Configuration Notes

### Bearer Token Format in Okta Admin Console

When configuring the Generic Database Connector application in Okta Admin Console, the bearer token **MUST** include the `Bearer ` prefix:

**Correct Format**:
```
Bearer da655feabd8ec0c3f89c1fb6e9f0ad39
```

**Incorrect Format** (will fail authentication):
```
da655feabd8ec0c3f89c1fb6e9f0ad39
```

The token value itself comes from the `scim.security.bearer.token` property in `./data/okta-scim/conf/config-*.properties`.

### SCIM Base URL

The SCIM Hostname should use the container hostname:
```
okta-scim 
```

This works because the OPP Agent and SCIM Server are on the same Docker network and can resolve container names.

### SQL Files and Database Initialization

The MariaDB container uses Docker's initialization feature (`/docker-entrypoint-initdb.d/`). All `.sql` files in the `./sql/` directory are automatically executed in alphabetical order on first container startup:

1. **init.sql** - Creates schema with 30-field USERS table and populates test data (15 users from LDIF with extended profiles, 10 entitlements)
2. **stored_proc.sql** - Creates 10 stored procedures for SCIM operations (CREATE_USER and UPDATE_USER support all 30 fields with 29 parameters)

**Important**: These scripts only run once when the database is first initialized. To reset:
```bash
docker compose down
rm -rf ./data/mysql
make start-logs
```

## Additional Documentation

This project includes multiple documentation files for different audiences:

- **QUICKSTART.md**: Fast setup guide for quick deployment
  - Minimal steps to get up and running
  - Essential commands only
  - Common issues and solutions
  - Perfect for experienced users or quick testing

- **README.md**: User-facing documentation with quick start, configuration guide, and troubleshooting
  - Comprehensive guide with emojis, mermaid diagrams, and table of contents
  - Suitable for end users and developers
  - Includes badges, architecture overview, and step-by-step instructions
  - Updated with Bearer token requirement and SQL initialization information

- **doc/Okta_Provisioning_Configuration.md**: Detailed Okta Admin Console configuration guide
  - Step-by-step instructions for configuring all stored procedures
  - Full parameter mapping for CREATE_USER and UPDATE_USER procedures
  - Screenshots and visual guides for each operation
  - Import operations (To Okta) and Provisioning operations (To App)
  - Testing procedures and troubleshooting tips
  - Perfect reference when setting up the Generic Database Connector with extended schema

- **doc/Okta_SCIM_Server.md**: Technical documentation for the SCIM Server (reverse-engineered)
  - Internal architecture and component breakdown (Spring Boot 3.5.0, Embedded Tomcat, HikariCP)
  - SCIM 2.0 API endpoints (Users, Groups, Entitlements, ServiceProviderConfig)
  - Authentication (Bearer token) and custom headers (X-OKTA-ONPREM-DATA)
  - Configuration files and auto-generation process
  - Logging, debugging, and performance tuning
  - Database connectivity and JDBC driver management
  - SSL/TLS configuration and certificate handling
  - **DISCLAIMER**: Educational purposes only, not official Okta documentation

- **CLAUDE.md** (this file): Technical documentation for AI assistants and developers
  - Detailed implementation details
  - Complete directory structure
  - Separated container architecture (okta-opp and okta-scim)
  - Comprehensive USERS table schema
  - SQL database initialization with extended stored procedures
  - Troubleshooting guides
  - Technical reference material
