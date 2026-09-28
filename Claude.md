# Claude.md - Project Documentation for AI Assistants

## Project Overview

Docker-based lab environment for the **Okta On-Prem SCIM Agent** with JDBC connectivity. Provides containerized setup for testing and developing Okta provisioning integrations with on-premises databases.

**Project:** okta-lab-onprem-jdbc-v2 | **Author:** Fabio Grasso <iam@fabiograsso.net>
**Quick Start:** [QUICKSTART.md](QUICKSTART.md)

> Design note: as of Okta's 2026.09.0 release, the legacy two-agent model
> (On-Prem Provisioning Agent "OPP" + standalone On-Prem SCIM Server) was
> replaced by a single consolidated **Okta On-Prem SCIM Agent**. This repo
> (`-v2`) reflects that consolidation and only deploys the single agent.

## Architecture

Three Docker services:

**1. MariaDB Database (`db`)**
- Image: `mariadb:11`, Port: 3306 (internal)
- Data: `./data/mysql`, SQL init: `./sql/` → `/docker-entrypoint-initdb.d/`
- Health checks enabled

**2. DBGate (`dbgate`)**
- Image: `dbgate/dbgate:latest`, Port: 8090 → 3000
- Access: http://localhost:8090, pre-configured for MariaDB
- Depends on: `db` health

**3. Okta On-Prem SCIM Agent (`okta-scim`)**
- Image: `quay.io/centos/centos:stream9-minimal` (linux/amd64)
- Components: Okta On-Prem SCIM Agent, OpenJDK 25, MySQL Connector/J 9.6.0 (auto-downloaded)
- Volumes: `./data/okta-scim/{logs,conf}`, `./docker/okta-scim/packages` (read-only)
- Depends on: `db` health

## Directory Structure

```
.
├── .env                          # Environment variables (gitignored)
├── .env-sample                   # Sample environment configuration
├── docker-compose.yml            # Docker services definition
├── Makefile                      # Build and deployment commands
├── README.md                     # User-facing documentation
├── CLAUDE.md                     # This file (AI assistant documentation)
├── data/                         # Persistent data (gitignored)
│   ├── mysql/                    # MariaDB data files
│   └── okta-scim/                # SCIM Agent data
│       ├── conf/                 # SCIM Agent registration/config files
│       └── logs/                 # SCIM Agent logs
├── docker/                       # Docker build contexts
│   └── okta-scim/                # SCIM Agent container
│       ├── Dockerfile            # SCIM Agent image definition
│       ├── entrypoint.sh         # SCIM Agent startup script
│       └── packages/             # SCIM Agent packages (not in git)
│           ├── OktaOnPremSCIMAgent*.rpm
│           ├── *.jar             # JDBC drivers
│           └── *.pem/*.crt       # Optional certificates
└── sql/                          # Database initialization scripts
    ├── init.sql                  # Schema and test data
    └── stored_proc.sql           # SCIM stored procedures
```

## Required Files (Not in Repository)

**SCIM Agent Files** (`./docker/okta-scim/packages/`):
1. **OktaOnPremSCIMAgent-*.rpm** (Required) - [Download](https://help.okta.com/en-us/content/topics/provisioning/opp/on-prem-scim-install.htm)
2. **JDBC Drivers** (Optional) - `*.jar` files. MySQL Connector/J 9.6.0 auto-downloaded. Additional drivers for MariaDB, PostgreSQL, Oracle, SQL Server supported. All jars copied to `/opt/OktaOnPremSCIMAgent/userlib/`. See [Generic DB Connector docs](https://help.okta.com/en-us/content/topics/provisioning/opc/connectors/on-prem-connector-generic-db.htm).
3. **CA Certificates** (Optional) - `*.pem` or `*.crt` for custom VPN

## Database Initialization

MariaDB auto-executes SQL scripts from `./sql/` on first startup via `/docker-entrypoint-initdb.d/`.

### Schema and Test Data (`sql/init.sql`)

**USERS Table** (25 fields):
- **Required (5):** USER_ID (PK), USERNAME, FIRSTNAME, LASTNAME, EMAIL
- **Optional (20):** Identity (MIDDLENAME, DISPLAYNAME, NICKNAME), Contact (MOBILEPHONE, STREETADDRESS, CITY, STATE, ZIPCODE, COUNTRYCODE, TIMEZONE), Work (TITLE, ORGANIZATION, DEPARTMENT, EMPLOYEENUMBER, MANAGER, MANAGERID), Dates (HIREDATE, TERMINATIONDATE), Security (PASSWORD_HASH, IS_ACTIVE)

**ENTITLEMENTS Table:**
- ENT_ID (INT PK), ENT_NAME (VARCHAR 100 UNIQUE), ENT_DESCRIPTION (VARCHAR 255)

**USERENTITLEMENTS Table:**
- USERENTITLEMENT_ID (UUID PK), USER_ID (FK), ENT_ID (FK), ASSIGNEDDATE, Unique constraint (USER_ID, ENT_ID)

**Test Data:**
- 15 Star Wars characters with extended profiles (Luke, Leia, Han, Obi-Wan, Yoda, etc.)
- Organizations: Jedi, Resistance, Empire, Droid with manager hierarchies
- 10 entitlements: VPN Access, GitHub Admin, AWS Console, Jira Admin, Confluence Edit, Database Read/Write, Slack Admin, Office 365, Salesforce
- Realistic role-based assignments

**Views (6):** V_USERENTITLEMENTS, V_INACTIVE_USERENTITLEMENTS, V_ACTIVE_USERS, V_INACTIVE_USERS, V_ENTITLEMENT_USAGE, V_USER_HIERARCHY

### Stored Procedures (`sql/stored_proc.sql`)

Based on Generic DB Connector Appendix A, adapted for MySQL/MariaDB:

1. **GET_ACTIVEUSERS()** - Returns all active users (all 25 fields)
2. **GET_ALL_ENTITLEMENTS()** - Returns all entitlements (ENT_ID, ENT_NAME, ENT_DESCRIPTION)
3. **GET_USER_BY_ID(p_user_id)** - Returns specific user (all 25 fields)
4. **GET_USER_ENTITLEMENT(p_user_id)** - Returns user's entitlements with details
5. **CREATE_USER(...)** - Creates user with 24 params (5 mandatory: user_id, username, firstname, lastname, email; 19 optional). Sets IS_ACTIVE=1.
6. **UPDATE_USER(...)** - Updates user with 24 params (5 mandatory, 19 optional)
7. **ACTIVATE_USER(p_user_id)** - Sets IS_ACTIVE=1
8. **DEACTIVATE_USER(p_user_id)** - Sets IS_ACTIVE=0
9. **ADD_ENTITLEMENT_TO_USER(p_user_id, p_ent_id)** - Assigns entitlement
10. **REMOVE_ENTITLEMENT_FROM_USER(p_user_id, p_ent_id)** - Revokes entitlement

**See also:** [Okta_Provisioning_Configuration.md](doc/Okta_Provisioning_Configuration.md), [Okta_SCIM_Server.md](doc/Okta_SCIM_Server.md)

## Configuration

**Environment Variables (.env):**
```bash
MARIADB_PORT=3306
MARIADB_ROOT_PASSWORD=oktademo
MARIADB_USER=oktademo
MARIADB_PASSWORD=oktademo
MARIADB_DATABASE=oktademo
```

**SCIM Agent** (`./data/okta-scim/`):
Registers with Okta via an **OAuth device-code flow** run through `make configure` (`configure_agent.sh`): prompts for the Okta org URL, prints a verification URL + code, and completes once approved in the browser. No bearer token or self-signed certificate is generated or required — unlike the legacy OPP Agent + On-Prem SCIM Server pair, there's nothing to upload as a "Public Key" in the Okta Admin Console. (The legacy cert secured the internal HTTPS hop between the OPP Agent and the standalone SCIM Server; that hop no longer exists now that the two are merged into one process.)
- **Config/registration files** - written to `./data/okta-scim/conf/` by `configure_agent.sh`
- **Logs** - `/var/log/OktaOnPremSCIMAgent/` → `./data/okta-scim/logs/`

> **TODO:** The exact registration marker file(s) `configure_agent.sh` writes
> (used by the entrypoint to detect "already registered") and the agent's
> real start command/binary path are still best-effort guesses - confirm
> against the actual RPM contents. See TODOs in
> `docker/okta-scim/entrypoint.sh` and `Dockerfile`.

## Build and Deployment Commands (Makefile)

```bash
make help            # Display all commands
make check-prereqs   # Run prerequisite checks
make build           # Build images (with prereq checks)
make rebuild         # Force rebuild (no cache)
make start           # Start services (detached)
make start-live      # Start with live logs
make start-logs      # Start detached + follow logs
make stop            # Stop and remove containers
make restart         # Stop then start
make restart-logs    # Restart + follow logs
make logs            # Follow logs (last 500 lines)
make kill            # Kill containers + remove orphans
make configure       # Interactive agent config
```

**Prerequisite Checks** (auto-run before start/build):
Verifies the SCIM Agent RPM (required), JDBC jars (info only), certs (warning only), .env file, MARIADB_* vars. Exits on critical failures.

**Interactive Configure:** `make configure` runs the agent's `configure_agent.sh` on the `okta-scim` container (requires running container).

## Setup Workflow

1. **Prepare packages:**
   ```bash
   mkdir -p docker/okta-scim/packages
   # Copy RPM (required) and certificates (optional)
   ```

2. **Configure environment:** `cp .env-sample .env` (edit if needed)

3. **Build:** `make build` (prereq checks run automatically)

4. **Start:** `make start-logs` (follows logs, initializes DB)

5. **Register the SCIM Agent:** `make configure` (enter org URL, approve device code in browser)

6. **Verify:** `docker compose exec db mariadb -u oktademo -poktademo oktademo -e "SELECT COUNT(*) FROM USERS;"` (expect 15)

7. **Access DBGate:** http://localhost:8090 (root/oktademo)

## Container Behavior

**SCIM Agent** (`./docker/okta-scim/entrypoint.sh`):
1. Display Okta logo
2. Create conf/log dirs and set permissions
3. Wait for registration (polls every 10s for a marker file under `${CONF_DIR}` - TODO: confirm exact marker)
4. Health check: validates `/ws/rest/jdbc_on_prem/scim/v2/Status` every 5 min
5. Start agent (foreground)

Registration (`make configure` → `configure_agent.sh`) runs separately/interactively and is not part of this startup sequence — it's what makes the marker file(s) appear. No certificate is generated (see Auth note below).

All config/logs persist to host, survive restarts.

## Database Access

**DBGate:** http://localhost:8090 (oktademo/oktademo)
**CLI:** `docker-compose exec db mariadb -u oktademo -poktademo oktademo`
**JDBC:** host=db, port=3306, db=oktademo, user/pass=oktademo

## Troubleshooting

**Status & Logs:**
```bash
docker-compose ps
make logs                                    # All services
docker compose logs -f {okta-scim|db}
tail -f ./data/okta-scim/logs/*.log
```

**SCIM Agent issues:**
1. Check logs: `./data/okta-scim/logs/`
2. Verify JDBC drivers: `./docker/okta-scim/packages/*.jar`
3. Test endpoint (no auth header needed - the new agent doesn't use bearer tokens):
   ```bash
   curl -ik https://localhost:1443/ws/rest/jdbc_on_prem/scim/v2/ServiceProviderConfig
   ```

**Database issues:**
```bash
docker-compose ps db
docker-compose exec db mariadb-admin ping
# Check .env variables
```

**Build failures:**
```bash
ls -la docker/okta-scim/packages/  # Verify packages exist
make rebuild                        # Rebuild without cache
```

**Prereq failures:**
- Missing RPM: Download from Okta docs (see error message)
- Missing .env: `cp .env-sample .env`
- JDBC drivers: Optional (MySQL auto-downloaded)
- Certificates: Optional (warning only, non-blocking)

**Configure command fails:**
- Start container first: `make start`
- `make: *** [configure] Error 137` appearing *after* the device code has been approved in the browser is expected and safe to ignore (Docker isn't officially supported for running the agent, and `configure_agent.sh` isn't designed to be attached to the way this lab attaches to it). Verify registration succeeded via `docker compose logs -f okta-scim` or the agent list in the Okta Admin Console (should show **OPERATIONAL**).

### Database Query Logging

Debug SQL queries by enabling MariaDB's general query log:

**Enable (temporary):**
```bash
docker compose exec db mariadb -u root -poktademo -e "SET GLOBAL general_log = 'ON';"
docker compose exec db mariadb -u root -poktademo -e "SET GLOBAL general_log_file = '/var/log/mysql/general.log';"
```

**Enable (permanent):** Add to docker-compose.yml db service:
```yaml
command:
  - --general-log=1
  - --general-log-file=/var/log/mysql/general.log
```
Then `make restart`

**View logs:**
```bash
docker compose exec db tail -f /var/log/mysql/general.log
docker compose exec db grep "CALL" /var/log/mysql/general.log
```

**Disable:** `docker compose exec db mariadb -u root -poktademo -e "SET GLOBAL general_log = 'OFF';"`

**Persist logs:** Add volume `./data/mysql-logs:/var/log/mysql` to docker-compose.yml, then `mkdir -p ./data/mysql-logs && make restart`

**Warning:** High I/O impact. Enable only for debugging. Shows all SQL with parameters.

## Development

**Modify containers:**
1. Edit `docker/okta-scim/{Dockerfile|entrypoint.sh}`
2. `make rebuild && make restart-logs`

**Add JDBC drivers:**
1. Place `.jar` in `./docker/okta-scim/packages/`
2. `make rebuild`
3. Verify: `docker compose exec okta-scim ls -la /opt/OktaOnPremSCIMAgent/userlib/`

**Certificate management (VPN CAs only):**
- Auto-updated at build time from `./docker/okta-scim/packages/*.{pem|crt}` to `/etc/pki/ca-trust/source/anchors/` (for corporate VPN/proxy interception, unrelated to agent auth)

**Schema changes:**
1. Edit `sql/init.sql` or `sql/stored_proc.sql`
2. `docker compose down && rm -rf ./data/mysql`
3. `make start-logs`
Note: SQL scripts run only on first init. For existing DBs, apply changes manually.

## Security & Known Issues

**Security:**
- Lab passwords only (not production-ready)
- .env/rpm/certs gitignored

**Known Issues:**
- Platform: linux/amd64 (macOS compat, possible ARM perf impact)
- Ports: 8090 (DBGate), 3306 (MariaDB internal)
- Check conflicts: `lsof -i :8090`

## References & Versions

**Documentation:**
- [Install the Okta On-Prem SCIM Agent](https://help.okta.com/en-us/content/topics/provisioning/opp/on-prem-scim-install.htm)
- [Generic DB Connector](https://help.okta.com/en-us/content/topics/provisioning/opc/connectors/on-prem-connector-generic-db.htm)
- [Okta 2026.09.0 Release Notes](https://help.okta.com/oie/en-us/content/topics/releasenotes/production.htm) - SCIM Server → SCIM Agent consolidation

**Versions:**
- MariaDB: 11 | DBGate: Latest | CentOS: Stream 9 Minimal
- OpenJDK: 25 Headless
- MySQL Connector/J: 9.6.0 (auto-downloaded)
- Okta On-Prem SCIM Agent: From RPM (version TBD once tested)

## Key Configuration Notes

**Auth:**
The legacy OPP Agent + On-Prem SCIM Server pair used a bearer token (`Bearer <value>`) plus a self-signed certificate uploaded as a "Public Key" in the Okta Admin Console — this secured the internal HTTPS hop between the two processes. The new consolidated agent drops both: registration is a one-time OAuth device-code flow (`make configure`), and there's no internal hop left to secure since the two legacy processes are now merged into one.

**Early Access feature flags (Settings → Features):**
- `On-prem Connector for Generic Databases`
- `Enable the Okta On-Premises SCIM Agent` (depends on the above)
- `Enable Incremental Import for On-prem Connector for Generic Databases provisioning` (optional, depends on the SCIM Agent flag)

**SCIM Base URL:**
Use container hostname `okta-scim` (containers on same Docker network)

**SQL Initialization:**
Scripts in `./sql/` auto-run alphabetically on first startup:
1. **init.sql** - Schema with 25-field USERS, test data (15 users, 10 entitlements), 6 views
2. **stored_proc.sql** - 10 procedures for SCIM operations

Reset: `docker compose down && rm -rf ./data/mysql && make start-logs`

## Additional Documentation

- **QUICKSTART.md** - Fast setup (minimal steps, essential commands)
- **README.md** - User guide (comprehensive with diagrams, badges, architecture)
- **doc/Okta_Provisioning_Configuration.md** - Admin Console config (procedures, parameters, screenshots, testing)
- **doc/Okta_SCIM_Server.md** - SCIM Agent internals (Spring Boot 3.5.0, SCIM 2.0 endpoints, auth, config, performance - educational only, not official)
- **CLAUDE.md** (this file) - Technical reference for AI assistants (implementation, architecture, schema, troubleshooting)
