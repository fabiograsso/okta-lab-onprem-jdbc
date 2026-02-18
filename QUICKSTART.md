# 🚀 Quick Start Guide

Get up and running with Okta OPP Agent + SCIM Server for Generic Database in minutes.

## Prerequisites

- Docker Desktop or Docker Engine with Docker Compose v2+
- Okta Organization with admin access
- Downloaded files from Okta (see step 1)

## Quick Instructions

### 1. Download Required Files

Download from Okta Help Center:

- **OPP Agent RPM**: [Doc](https://help.okta.com/oie/en-us/content/topics/provisioning/opp/opp-install-agent.htm)
- **SCIM Server RPM**: [Doc](https://help.okta.com/oie/en-us/content/topics/provisioning/opp/on-prem-scim-install.htm)

### 2. Organize Package Files

```bash
# Copy OPP Agent RPM
cp OktaProvisioningAgent-*.rpm ./docker/okta-opp/packages/

# Copy SCIM Server RPM
cp OktaOnPremScimServer-*.rpm ./docker/okta-scim/packages/

# Optional: If using VPN with custom certificates (e.g., PaloAlto GlobalProtect/Prisma Access)
# cp ../your_path/your_vpn_certificates.pem ./docker/okta-opp/packages/
# cp ../your_path/your_vpn_certificates.pem ./docker/okta-scim/packages/
```

### 3. Configure Environment

```bash
cp .env-sample .env
# Edit .env if needed (default values work for testing)
```

### 4. Build and Start

```bash
# Build Docker images
make build

# Start all services
make start-logs
```

### 5. Configure OPP Agent

Wait for the message: **"⏳ Waiting for configuration files"**

Then run the interactive configuration:

```bash
make configure
```

You will see the message:

```txt
[ YYYY-MM-DD HH:MM:SS.sss ] [ main ] [OppAgentConfigLoader] [  ] [INFO] - Register Mode successfully finished

Configuration successful.

Service can now be started by typing
systemctl start OktaProvisioningAgent.service
as root.
```

You don't need to run the `systemctl` command since the agent is already running in the container. The message indicates that the configuration files have been generated successfully.

Follow the prompts to connect to your Okta org.

### 6. Retrieve SCIM Credentials

The credentials are automatically displayed in the logs. You can also retrieve them:

```bash
# Get bearer token (look for scim.security.bearer.token)
cat ./data/okta-scim/conf/config-*.properties | grep bearer.token

# Get public certificate
cat ./data/okta-scim/certs/OktaOnPremScimServer-*.crt
```

**Example output**:

```properties
scim.security.bearer.token=da655feabd8ec0c3f89c1fb6e9f0ad39
```

### 7. Configure Okta App Integration

1. In Okta Admin Console, go to **Applications** → **Browse App Catalog**
2. Search for **"On-prem connector for Generic Databases"**
3. Add the application
4. In the **Provisioning** tab, configure:

   **SCIM Connection**:
   - **SCIM Hostname**: `okta-scim`
   - **SCIM Bearer Token**: `Bearer da655feabd8ec0c3f89c1fb6e9f0ad39` ⚠️ **Include "Bearer " prefix!**
   - **Upload Certificate**: Use the `.crt` file from step 6

   **Database Connection**:
   - **Database Type**: MySQL (works with both MySQL and MariaDB)
   - **IP/Domain name**: `db`
   - **Port**: `3306`
   - **Database Name**: `oktademo`
   - **Username**: `oktademo`
   - **Password**: `oktademo`

   > Note: Database type should be set to "MySQL" in Okta configuration even though MariaDB is being used, as MariaDB is MySQL-compatible.

   **Stored Procedures**: See [detailed configuration guide](doc/Okta_Provisioning_Configuration.md) for configuring all 10 stored procedures (import/provisioning operations)

5. Configure attribute mappings
6. Assign users or groups to the application

### 8. Database Schema

The database schema includes:

- **USERS** table: USER_ID (PK), USERNAME (UNIQUE VARCHAR(100)), FIRSTNAME (VARCHAR(100) nullable), LASTNAME (VARCHAR(100) nullable), EMAIL, MANAGER, TITLE, IS_ACTIVE
- **ENTITLEMENTS** table: ENT_ID (INT PK, values 1-10), ENT_NAME (UNIQUE), ENT_DESCRIPTION
- **USERENTITLEMENTS** junction table: Links users to entitlements with assignment dates

### 9. Test Provisioning

The database comes pre-populated with 15 test users (Star Wars characters). Try:

```bash
# View test users in DBGate
open http://localhost:8090

# Or via command line
docker compose exec db mariadb -u oktademo -poktademo oktademo -e "SELECT * FROM USERS;"

# Test stored procedures
docker compose exec db mariadb -u oktademo -poktademo oktademo -e "CALL GET_ACTIVEUSERS();"
```

Assign a user in Okta to test provisioning to the database.

## 🔍 Verify Everything Works

```bash
# Check all containers are running
docker compose ps

# View logs
make logs
```

## 📚 Full Documentation

- [README.md](README.md) - Complete setup and configuration guide
- [doc/Okta_Provisioning_Configuration.md](doc/Okta_Provisioning_Configuration.md) - Detailed Okta stored procedures configuration

## 🔗 References

1. [Install the Okta Provisioning Agent](https://help.okta.com/oie/en-us/content/topics/provisioning/opp/opp-install-agent.htm)
2. [Install the Okta On-prem SCIM Server](https://help.okta.com/oie/en-us/content/topics/provisioning/opp/on-prem-scim-install.htm)
3. [On-premises Connector for Generic Databases](https://help.okta.com/oie/en-us/content/topics/provisioning/opc/connectors/on-prem-connector-generic-db.htm)

---

**Need help?** Check the [full README](README.md) or [troubleshooting guide](CLAUDE.md#troubleshooting).
