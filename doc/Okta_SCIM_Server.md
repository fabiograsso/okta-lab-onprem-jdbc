# Okta On-Prem SCIM Server - Technical Documentation

---

> ## ⚠️ DISCLAIMER
> 
> **This document is NOT official Okta documentation.**
> 
> The information contained in this document has been obtained through **reverse engineering and analysis of the Okta On-Prem SCIM Server JAR file** using automated code analysis tools (*Claude Code*). The content is provided for **educational and learning purposes only**.
> 
> ### Important Notes
> 
> 1. **No Official Documentation**: Okta does not publish official API documentation or technical specifications for the On-Prem SCIM Server's internal workings.
> 
> 2. **Unsupported Use**: The **ONLY officially supported way** to use the Okta On-Prem SCIM Server is:
>    - Through the **Okta Provisioning Agent (OPP Agent)**
>    - Via configuration in the **Okta Admin Console**
>    - Following official Okta documentation and guidelines
> 
> 3. **Direct API Access Not Supported**: Directly calling the SCIM Server APIs documented here is **not supported by Okta** and should only be done for:
>    - Educational purposes
>    - Testing and debugging in lab environments
>    - Understanding the system architecture
>    - Troubleshooting with Okta Support guidance
> 
> 4. **Use at Your Own Risk**: Any use of this information outside of the officially supported methods is at your own risk and may:
>    - Void support agreements
>    - Cause unexpected behavior
>    - Break with future updates
>    - Introduce security vulnerabilities
> 
> 5. **Official Documentation**: Always refer to official Okta documentation:
>    - [Install the Okta On-prem SCIM Server](https://help.okta.com/oie/en-us/content/topics/provisioning/opp/> on-prem-scim-install.htm)
>    - [On-premises Connector for Generic Databases](https://help.okta.com/oie/en-us/content/topics/provisioning/> opc/connectors/on-prem-connector-generic-db.htm)
>
> **By reading this document, you acknowledge that this information is for learning purposes only and that you > will use the Okta On-Prem SCIM Server only through officially supported methods in production environments.**

---

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Authentication](#authentication)
- [SCIM Endpoints](#scim-endpoints)
- [Health Check](#health-check)
- [X-OKTA-ONPREM-DATA Header](#x-okta-onprem-data-header)
- [Configuration](#configuration)
- [Logging and Debugging](#logging-and-debugging)
- [Database Connectivity](#database-connectivity)
- [Performance Tuning](#performance-tuning)
- [Related Documentation](#related-documentation)

---

## Overview

The Okta On-Prem SCIM Server is a **Spring Boot 3.5.0** application that implements the SCIM 2.0 protocol for provisioning users, groups, and entitlements to on-premises databases. It acts as a bridge between Okta's cloud provisioning service and your local database infrastructure.

### Key Characteristics

- **Application Type**: Spring Boot 3.5.0 JAR (executable with embedded Tomcat)
- **Main Class**: `com.okta.server.scim.ScimServerApplication`
- **Launcher**: `org.springframework.boot.loader.launch.JarLauncher` (Spring Boot fat JAR)
- **JAR Location**: `data/okta-scim/conf/OktaOnPremScimServer-<version>.jar`
- **Default Port**: 1443 (HTTPS)
- **Base Context Path**: `/ws/rest`
- **Protocol**: HTTPS only (TLS 1.2, TLS 1.3)

---

## Architecture

### Application Stack

```mermaid
flowchart TB
 subgraph SCIM["<b>Okta On-Prem SCIM Server</b>"]
    direction TB
        E["Spring Boot 3.5.0"]
        F["Embedded Tomcat 10.x<br>- HTTPS/TLS<br>- Port 1443"]
        H["JDBC Connector:<br>- HikariCP Pool<br>- Stored Proc Executor"]
        G["REST Controllers:<br>- UserController<br>- GroupController<br>- EntitlementController<br>- StatusController"]
  end
 subgraph DB["<b>Database</b>"]
    direction TB
        I["Table USERS<br>Table ENTITLEMENTS<br>Table USERENTITLEMENTS<br>Stored Procedures"]
  end
    E L_E_F_0@-.- F & H & G
    OC["<b>Okta Cloud</b>"] -- HTTPS --- OPP["<b>Okta Provisioning Agent</b>"]
    SCIM -- JDBC Connection --- DB
    OPP -- "HTTPS + Bearer Token +<br>X-OKTA-ONPREM-DATA header" --- SCIM

    style OC fill:#e1f5ff
    style OPP fill:#fff4e6
    style SCIM fill:#e8f5e9
    style DB fill:#fce4ec

    L_E_F_0@{ curve: natural } 
    L_E_H_0@{ curve: natural } 
    L_E_G_0@{ curve: natural }
```

### Core Components

#### 1. Embedded Tomcat Server
- **Version**: Apache Tomcat 10.x
- **Protocol**: HTTPS with NIO connector
- Bundled with **Spring Boot 3.5.0**:

#### 2. REST Controllers

Located in `BOOT-INF/classes/com/okta/server/scim/controller/`:

| Controller | Purpose | Base Path |
|------------|---------|-----------|
| `UserController.java` | User CRUD operations | `/{app}/scim/v2/Users` |
| `GroupController.java` | Group operations | `/{app}/scim/v2/Groups` |
| `EntitlementController.java` | Entitlement management | `/{app}/scim/v2/Entitlements` |
| `StatusController.java` | Health check | `/{app}/scim/v2/Status` |
| `ServiceProviderConfigController.java` | SCIM capabilities | `/{app}/scim/v2/ServiceProviderConfig` |
| `SchemaImportController.java` | SCIM schema definitions | `/{app}/scim/v2/Schemas` |
| `ResourceTypeController.java` | SCIM resource types | `/{app}/scim/v2/ResourceTypes` |
| `ScimExceptionHandler.java` | Global exception handling | N/A |

#### 3. JDBC Connector

Located in `BOOT-INF/classes/com/okta/server/scim/connector/jdbc/`:

- **DataSource Management**: HikariCP connection pooling
- **Executor**: Stored procedure execution engine
- **Service Layer**: Workflow orchestration for SCIM operations
- **Configuration**: Dynamic connector configuration via properties

#### 4. Security Layer

Located in `BOOT-INF/classes/com/okta/server/scim/security/`:

- **Bearer Token Authentication**: Simple token-based auth
- **SSL/TLS**: Server-side certificate authentication
- **No mTLS**: Client certificate authentication disabled (`server.ssl.client-auth=NONE`)

---

## Authentication

### Bearer Token Authentication

The SCIM server uses **Bearer token authentication** for all SCIM API requests.

#### Configuration

Bearer token is configured in the properties file:

**File**: `data/okta-scim/conf/config-{CUSTOMER_ID}.properties`

```properties
scim.security.bearer.token=d5307740c879491cedecf70c2225776b
```

This token is **auto-generated** during first startup by the RPM installer (or in our case, the Docker entrypoint script).

#### Usage

**Header Format**:
```
Authorization: Bearer <token>
```

**Example**:
```bash
curl -k -H "Authorization: Bearer d5307740c879491cedecf70c2225776b" \
  https://localhost:1443/ws/rest/jdbc_on_prem/scim/v2/Status
```

#### Important Notes

1. **Case Sensitive**: The word "Bearer" must be capitalized
2. **Space Required**: There must be exactly one space between "Bearer" and the token
3. **Token Length**: 32 characters (hex string)
4. **Rotation**: To change the token, modify the properties file and restart the SCIM server

---

## SCIM Endpoints

### Endpoint URL Pattern

All SCIM endpoints follow this pattern:

```
https://{host}:{port}/ws/rest/{app}/scim/v2/{resource}
```

Where:
- `{host}`: SCIM server hostname (e.g., `okta-scim` or `localhost`)
- `{port}`: SCIM server port (default: `1443`)
- `{app}`: Application/connector name (e.g., `jdbc_on_prem`)
- `{resource}`: SCIM resource type (`Users`, `Groups`, `Entitlements`, etc.)

In addition to the **[Authentication header (Bearer Token)](#authentication)**, these endpoints require the **[X-OKTA-ONPREM-DATA header](#x-okta-onprem-data-header)**, as described in the dedicated section.

### User Operations

**Base Path**: `{app}/scim/v2/Users`

#### List Users
```http
GET /{app}/scim/v2/Users?startIndex=1&count=100
Authorization: Bearer {token}
X-OKTA-ONPREM-DATA: {base64_encoded_config}
```

**Query Parameters**:
- `startIndex` (optional): Starting index for pagination (1-based)
- `count` (optional): Number of results to return
- `filter` (optional): SCIM filter expression

**Response**: SCIM ListResponse with user resources

#### Get User by ID
```http
GET /{app}/scim/v2/Users/{userId}
Authorization: Bearer {token}
X-OKTA-ONPREM-DATA: {base64_encoded_config}
```

**Path Parameters**:
- `{userId}`: User identifier (typically email or username)

**Response**: SCIM User resource

#### Create User
```http
POST /{app}/scim/v2/Users
Authorization: Bearer {token}
X-OKTA-ONPREM-DATA: {base64_encoded_config}
Content-Type: application/json

{
  "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
  "userName": "john.doe",
  "name": {
    "givenName": "John",
    "familyName": "Doe"
  },
  "emails": [
    {
      "value": "john.doe@example.com",
      "primary": true
    }
  ],
  "active": true
}
```

**Response**: 201 Created with SCIM User resource

#### Update User
```http
PUT /{app}/scim/v2/Users/{userId}
Authorization: Bearer {token}
X-OKTA-ONPREM-DATA: {base64_encoded_config}
Content-Type: application/json

{
  "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
  "id": "{userId}",
  "userName": "john.doe",
  "name": {
    "givenName": "John",
    "familyName": "Doe"
  },
  "active": false
}
```

**Response**: 200 OK with updated SCIM User resource

### Group Operations

**Base Path**: `{app}/scim/v2/Groups`

#### List Groups
```http
GET /{app}/scim/v2/Groups
Authorization: Bearer {token}
X-OKTA-ONPREM-DATA: {base64_encoded_config}
```

**Response**: SCIM ListResponse with group resources

### Entitlement Operations

**Base Path**: `{app}/scim/v2/Entitlements`

#### List Entitlements
```http
GET /{app}/scim/v2/Entitlements
Authorization: Bearer {token}
X-OKTA-ONPREM-DATA: {base64_encoded_config}
```

**Response**: SCIM ListResponse with entitlement resources

#### Get Entitlement by ID
```http
GET /{app}/scim/v2/Entitlements/{id}
Authorization: Bearer {token}
X-OKTA-ONPREM-DATA: {base64_encoded_config}
```

**Response**: SCIM Entitlement resource

### SCIM Metadata Endpoints

#### Service Provider Configuration
```http
GET /{app}/scim/v2/ServiceProviderConfig
Authorization: Bearer {token}
X-OKTA-ONPREM-DATA: {base64_encoded_config}
```

Returns SCIM server capabilities (supported operations, bulk operations, filtering, etc.)

#### Schemas
```http
GET /{app}/scim/v2/Schemas
Authorization: Bearer {token}
X-OKTA-ONPREM-DATA: {base64_encoded_config}
```

Returns SCIM schema definitions for User, Group, and custom resources.

#### Resource Types
```http
GET /{app}/scim/v2/ResourceTypes
Authorization: Bearer {token}
X-OKTA-ONPREM-DATA: {base64_encoded_config}
```

Returns available SCIM resource types (User, Group, Entitlement).

---

## Health Check

### Status Endpoint

The Status endpoint is the **only endpoint that does NOT require the `X-OKTA-ONPREM-DATA` header**. It's designed for health checks and monitoring.

**Endpoint**: `{app}/scim/v2/Status`

**Method**: `GET`

**Authentication**: Bearer token only

**Example**:
```bash
curl -k -H "Authorization: Bearer d5307740c879491cedecf70c2225776b" \
  https://localhost:1443/ws/rest/jdbc_on_prem/scim/v2/Status
```

**Success Response**:
```
HTTP/1.1 200 OK
Content-Type: text/plain;charset=UTF-8
Content-Length: 27

✅ Scim Server is running.
```

**Use Cases**:
- Docker health checks
- Load balancer health probes
- Monitoring systems (Nagios, Prometheus, etc.)
- Startup validation scripts

---

## X-OKTA-ONPREM-DATA Header

### Purpose

The `X-OKTA-ONPREM-DATA` header is a **custom HTTP header** that contains the **connector configuration** required for SCIM operations. It's automatically added by the **Okta Provisioning Agent** when forwarding requests to the SCIM server.

### Contents

The header contains a **Base64-encoded JSON payload** with:
- **Database connection details**: JDBC URL, username, password
- **Stored procedure mappings**: Which stored procedures to call for each SCIM operation
- **Attribute mappings**: How SCIM attributes map to database columns/parameters
- **Connector metadata**: Connector type, version, configuration version

### Why It's Required

1. **Multi-tenancy**: The SCIM server can serve multiple connectors simultaneously
2. **Dynamic Configuration**: Each request includes its own configuration, allowing runtime changes
3. **Security**: Configuration is passed per-request rather than stored on the SCIM server
4. **Flexibility**: Different Okta apps can use different database configurations

### Flow Diagram

```mermaid
sequenceDiagram
    participant OC as Okta Cloud
    participant OPP as Okta Provisioning Agent
    participant SCIM as Okta On-Prem<br/>SCIM Server
    participant DB as On-prem<br/>Database

    Note over OC: 1. User creates<br/>provisioning request

    OC->>OPP: 2. Send request to Agent

    Note over OPP: 3. Retrieves<br/>DB config and Bearer Token<br/>from Okta
    Note over OPP: 4. Encodes config<br/>as Base64
    Note over OPP: 5. Adds headers:<br/>'X-OKTA-ONPREM-DATA'<br/>and 'Authorization'

    OPP->>SCIM: 6. Forward to SCIM Server<br/>(HTTPS + headers)

    Note over SCIM: 7. Check Authorization Token
    Note over SCIM: 8. Decode headers
    Note over SCIM: 9. Extract from DB config:<br/>- JDBC URL<br/>- Credentials<br/>- Stored procs
    Note over SCIM: 10. Execute operation

    SCIM->>DB: 11. JDBC call

    Note over DB: 12. Execute Stored Procedure

    DB-->>SCIM: Result
    SCIM-->>OPP: SCIM Response
    OPP-->>OC: Provisioning Result
```

### Error Response

If the header is missing, the SCIM server returns:

```json
{
  "schemas": ["urn:ietf:params:scim:api:messages:2.0:Error"],
  "scimType": "MISSING_ATTRIBUTE",
  "detail": "Missing X-OKTA-ONPREM-DATA header",
  "status": 400
}
```

**HTTP Status**: `400 Bad Request`

### Testing Without Agent

For **development and debugging**, you can manually construct the header:

```bash
# Example connector config (JSON)
CONFIG='{
  "jdbcUrl": "jdbc:mysql://db:3306/oktademo",
  "username": "oktademo",
  "password": "oktademo",
  "procedures": {
    "listUsers": "GET_ACTIVEUSERS",
    "getUser": "GET_USER_BY_ID",
    "createUser": "CREATE_USER",
    "updateUser": "UPDATE_USER"
  }
}'

# Base64 encode
ENCODED=$(echo -n "$CONFIG" | base64)

# Make request with header
curl -k \
  -H "Authorization: Bearer d5307740c879491cedecf70c2225776b" \
  -H "X-OKTA-ONPREM-DATA: $ENCODED" \
  https://localhost:1443/ws/rest/jdbc_on_prem/scim/v2/Users
```

**Note**: The actual header format and schema may vary by connector type and version. Always refer to Okta documentation and support for the correct configuration when using the agent in production.

---

## Configuration

### Configuration Files

All configuration is stored in: `data/okta-scim/conf/`

#### 1. Application Properties

**File**: `config-{CUSTOMER_ID}.properties`

```properties
# HTTPS Configuration
server.port=1443
server.servlet.context-path=/ws/rest
server.ssl.enabled=true

# SSL/TLS Certificate
server.ssl.key-store-type=PKCS12
server.ssl.key-store=/etc/pki/tls/private/OktaOnPremScimServer-{CUSTOMER_ID}.p12
server.ssl.key-store-password={auto_generated}
server.ssl.key-alias=okscimservercert

# TLS Protocols
server.ssl.enabled-protocols=TLSv1.2,TLSv1.3

# Client Authentication (disabled)
server.ssl.client-auth=NONE

# Request Size
server.max-http-request-header-size=10KB

# Bearer Token Authentication
scim.security.bearer.token={auto_generated}

# HikariCP Database Connection Pool
app.datasource.hikari.maximumPoolSize=10
app.datasource.hikari.minimumIdle=0
app.datasource.hikari.connectionTimeout=30000
app.datasource.hikari.validationTimeout=3000
app.datasource.hikari.idleTimeout=90000
app.datasource.hikari.keepaliveTime=60000
app.datasource.hikari.maxLifetime=180000
app.datasource.hikari.initializationFailTimeout=0

# Logging Configuration
logging.level.root=DEBUG
logging.level.org.springframework.web=DEBUG
logging.level.org.apache.catalina=DEBUG
logging.level.com.okta.server.scim=DEBUG
logging.level.org.springframework.jdbc=DEBUG

logging.pattern.file=%d{yyyy-MM-dd'T'HH:mm:ss.SSSXXX}  [pid:${PID:-unknown}] [%thread] %class{36}:%line - %msg%n
logging.pattern.console=1
```

#### 2. Customer ID Configuration

**File**: `customer-id.conf`

```bash
CUSTOMER_ID=myorg
```

Used to namespace configuration and certificates for multi-instance deployments.

#### 3. JVM Configuration

**File**: `jvm.conf`

```bash
JAVA_OPTS="-Xmx2048m -Xms1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

Java memory and garbage collection settings.

### Certificate Files

Stored in: `data/okta-scim/certs/`

#### Auto-Generated Certificates

The entrypoint script automatically generates:

1. **Public Certificate**: `OktaOnPremScimServer-{CUSTOMER_ID}.crt`
   - 4096-bit RSA
   - 10-year validity
   - Self-signed
   - Format: PEM (X.509)

2. **Private Key**: `OktaOnPremScimServer-{CUSTOMER_ID}.key`
   - RSA private key
   - Format: PEM (PKCS#8)

3. **PKCS12 Keystore**: `OktaOnPremScimServer-{CUSTOMER_ID}.p12`
   - Contains certificate + private key
   - Password: Auto-generated (stored in properties file)
   - Alias: `okscimservercert`

---

## Logging and Debugging

### Log Files

**Location**: `/var/log/OktaOnPremScimServer/` (mapped to `data/okta-scim/logs/` on host if using my Docker Compose implementation)

**Files**:
- `application.log` - Main application log

### Log Levels

Configured in `config-{CUSTOMER_ID}.properties`:

```properties
logging.level.root=DEBUG
logging.level.org.springframework.web=DEBUG           # HTTP requests/responses
logging.level.org.apache.catalina=DEBUG               # Tomcat server
logging.level.org.apache.coyote=DEBUG                 # HTTP connector
logging.level.org.apache.tomcat=DEBUG                 # Tomcat internals
logging.level.com.zaxxer.hikari=DEBUG                 # Connection pool
logging.level.com.okta.server.scim=DEBUG              # SCIM operations
logging.level.org.springframework.jdbc=DEBUG          # JDBC operations
```

**Available Levels**: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`, `OFF`

### Log Format

**File Pattern**:
```
%d{yyyy-MM-dd'T'HH:mm:ss.SSSXXX}  [pid:${PID:-unknown}] [%thread] %class{36}:%line - %msg%n
```

**Example**:
```
2026-02-17T11:54:32.123+00:00  [pid:42] [https-jsse-nio-1443-exec-1] c.o.s.s.controller.UserController:87 - Creating user: john.doe@example.com
```

### Debugging SCIM Operations

Enable detailed JDBC logging to see SQL queries:

```properties
logging.level.org.springframework.jdbc.core=TRACE
```

This logs:
- SQL statements before execution
- Parameter values
- Result sets
- Transaction boundaries

### Common Log Patterns

**TLS Handshake Failures**:
```
Handshake failed for client connection from IP address [192.168.65.1]
```
**Cause**: Client doesn't trust the self-signed certificate (expected)

**Missing Header**:
```
Missing X-OKTA-ONPREM-DATA header
```
**Cause**: Direct API call without Okta Provisioning Agent

**JDBC Connection Issues**:
```
HikariPool - Exception during pool initialization
```
**Cause**: Database not reachable or credentials incorrect

**Stored Procedure Errors**:
```
CallableStatementCallback; ERROR 1305 (42000): PROCEDURE oktademo.CREATE_USER does not exist
```
**Cause**: Stored procedure not created in database

---

## Database Connectivity

### Connection Pooling

The SCIM server uses **HikariCP** for database connection pooling:

```properties
app.datasource.hikari.maximumPoolSize=10              # Max connections
app.datasource.hikari.minimumIdle=0                   # Min idle connections
app.datasource.hikari.connectionTimeout=30000         # 30 seconds
app.datasource.hikari.validationTimeout=3000          # 3 seconds
app.datasource.hikari.idleTimeout=90000               # 90 seconds
app.datasource.hikari.keepaliveTime=60000             # 60 seconds
app.datasource.hikari.maxLifetime=180000              # 180 seconds
app.datasource.hikari.initializationFailTimeout=0     # Fail immediately
```

### JDBC Drivers

**Location**: `/opt/OktaOnPremScimServer/userlib/`

**Copied from**: `docker/okta-scim/packages/*.jar`

**Supported Drivers**:
- MySQL Connector/J: `mysql-connector-j-9.6.0.jar`
- PostgreSQL: `postgresql-*.jar`
- Oracle JDBC: `ojdbc*.jar`
- SQL Server: `mssql-jdbc-*.jar`

### Connection Configuration

Database connection details are provided in the `X-OKTA-ONPREM-DATA` header on each request:

```json
{
  "jdbcUrl": "jdbc:mysql://db:3306/oktademo",
  "username": "oktademo",
  "password": "oktademo",
  "driverClassName": "com.mysql.cj.jdbc.Driver"
}
```

---

## Performance Tuning

### JVM Tuning

**For small workloads** (< 100 users):
```bash
JAVA_OPTS="-Xmx1024m -Xms512m -XX:+UseG1GC"
```

**For medium workloads** (100-1000 users):
```bash
JAVA_OPTS="-Xmx2048m -Xms1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

**For large workloads** (1000+ users):
```bash
JAVA_OPTS="-Xmx4096m -Xms2048m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+ParallelRefProcEnabled"
```

### HikariCP Tuning

**For high throughput**:
```properties
app.datasource.hikari.maximumPoolSize=20
app.datasource.hikari.minimumIdle=5
app.datasource.hikari.connectionTimeout=30000
```

**For low latency**:
```properties
app.datasource.hikari.maximumPoolSize=10
app.datasource.hikari.minimumIdle=2
app.datasource.hikari.connectionTimeout=5000
```

---

## Related Documentation

- [QUICKSTART.md](../QUICKSTART.md) - Fast setup guide
- [README.md](../README.md) - User-facing documentation
- [Okta_Provisioning_Configuration.md](Okta_Provisioning_Configuration.md) - Okta Admin Console setup guide