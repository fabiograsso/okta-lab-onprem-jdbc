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

### 5. Enable Early Access Features

In Okta Admin Console, go to **Settings** → **Features** and enable:

- **On-prem Connector for Generic Databases**
- **Enable the Okta On-Premises SCIM Agent**
- *(optional)* **Enable Incremental Import for On-prem Connector for Generic Databases provisioning**

### 6. Create the App and Add the Agent

1. In Okta Admin Console, go to **Applications** → **Browse App Catalog**
2. Search for and add **"On-prem connector for Generic Databases"**
3. In the **Provisioning** tab, click **Enable Provisioning**, then **"+ Add first agent"**
4. Select **For Linux (x64 RPM)** — this shows the install command:

   ```bash
   sudo INSTALL_MODE=agent yum localinstall OktaOnPremSCIMAgent-<version>.rpm
   ```

   This lab's Dockerfile already runs the equivalent `rpm` install — you don't need to run this manually inside the container.

### 7. Register the Agent

Run the interactive registration script:

```bash
make configure
```

Follow the prompts: enter your Okta org URL, then open the printed URL in a browser and approve the device code. Once approved, refresh the agent list in the Admin Console — the agent should show as **OPERATIONAL**.

> ⚠️ **Expected error**: after approving the device code, you'll likely see `make: *** [configure] Error 137` in the terminal. This is expected and safe to ignore — Docker isn't an officially supported way to run the agent, and this happens because `configure_agent.sh` doesn't manage the process the way this lab attaches to it. Registration still completes successfully — verify with `docker compose logs -f okta-scim` or by checking the agent list in the Okta Admin Console (it should show as **OPERATIONAL**).

Select the agent and click **Next**, then configure the database connection:

- **Database Type**: MySQL (works with both MySQL and MariaDB)
- **IP/Domain name**: `db`
- **Port**: `3306`
- **Database Name**: `oktademo`
- **Username**: `oktademo`
- **Password**: `oktademo`
- Under **Additional Database Properties**, add key `allowMultiQueries` with value `true`

Click **Test and finish setup**.

> Note: Database type should be set to "MySQL" in Okta configuration even though MariaDB is being used, as MariaDB is MySQL-compatible.

Once connected, the rest of the setup (attribute mappings, stored procedures for import/provisioning, assigning users) is unchanged from previous versions — see the [detailed configuration guide](doc/Okta_Provisioning_Configuration.md).

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
