# 🚀 Quick Start Guide

Get up and running with the Okta On-Prem SCIM Agent for Generic Database in minutes.

## Prerequisites

- Docker Desktop or Docker Engine with Docker Compose v2+
- Okta Organization with admin access
- Downloaded files from Okta (see step 1)

## Quick Instructions

### 1. Download Required Files

Download from Okta Help Center:

- **On-Prem SCIM Agent RPM**: [Doc](https://help.okta.com/en-us/content/topics/provisioning/opp/on-prem-scim-install.htm)

### 2. Organize Package Files

```bash
# Copy On-Prem SCIM Agent RPM
cp OktaOnPremSCIMAgent-*.rpm ./docker/okta-scim/packages/

# Optional: If using VPN with custom certificates (e.g., PaloAlto GlobalProtect/Prisma Access)
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

### 5. Configure the On-Prem SCIM Agent

> 📢 **TODO**: Once the real `OktaOnPremSCIMAgent` RPM is tested, verify and update the exact registration prompts/flow of `configure_agent.sh` below.

Run the interactive configuration/registration script:

```bash
make configure
```

Follow the prompts to connect to your Okta org.

### 6. Retrieve SCIM Agent Credentials

The agent's details are automatically displayed in the logs. You can also retrieve the public certificate:

```bash
# Get public certificate
cat ./data/okta-scim/certs/OktaOnPremSCIMAgent-*.crt
```

> 📢 **Note**: Earlier versions of this lab also retrieved a bearer token here. Per Okta's 2026.09.0 release notes, the consolidated agent was built to reduce dependencies, and it's not yet confirmed whether bearer-token auth is still required — **TODO**: verify against the real agent and update this step.

### 7. Configure Okta App Integration

1. In Okta Admin Console, go to **Applications** → **Browse App Catalog**
2. Search for **"On-prem connector for Generic Databases"**
3. Add the application
4. In the **Provisioning** tab, configure:

   **SCIM Connection**:
   - **SCIM Hostname**: `okta-scim`
   - **Upload Certificate**: Use the `.crt` file from step 6
   - *(TODO: confirm whether a bearer token field is still present in the app setup with the new agent)*

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

1. [Install the Okta On-prem SCIM Agent](https://help.okta.com/en-us/content/topics/provisioning/opp/on-prem-scim-install.htm)
2. [On-premises Connector for Generic Databases](https://help.okta.com/en-us/content/topics/provisioning/opc/connectors/on-prem-connector-generic-db.htm)
3. [Okta 2026.09.0 Release Notes](https://help.okta.com/oie/en-us/content/topics/releasenotes/production.htm) - Announcement of the SCIM Server → SCIM Agent consolidation

---

**Need help?** Check the [full README](README.md) or [troubleshooting guide](CLAUDE.md#troubleshooting).
