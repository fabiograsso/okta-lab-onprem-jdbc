#!/bin/bash
#
# Author: Fabio Grasso <fabio.grasso@okta.com>
# Version: 1.0.0
# License: Apache-2.0
# Description: Entrypoint docker script to for the Okta SCIM Server
#
# Usage: ./entrypoint.sh
#
# -----------------------------------------------------------------------------
set -e
echo "                                                                
                  ████          ████                              
                  ████          ████                              
       █████      ████    ████  █████        ████   ███           
    ██████████    ████   █████  ████████  █████████████           
  ██████████████  ████  █████   █████   ███████████████           
 █████      █████ █████████     ████    ████       ████           
 ████        ████ ████████      ████   ████        ████           
 ████        ████ ██████████    ████    ████       ████           
  █████    ██████ ████  █████   ████    █████    ██████           
   █████████████  ████   ██████ ████████ ███████████████         
    ██████████    ████     █████ ███████   ████████ █████         

"

#!/bin/bash

# Create symllink for certficates to avoid having to mount each file individually
touch /opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-${CUSTOMER_ID}.crt
touch /opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-${CUSTOMER_ID}.key
touch /opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-${CUSTOMER_ID}.p12
touch /opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-${CUSTOMER_ID}.p12.pass
ln -s /opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-${CUSTOMER_ID}.crt      /etc/pki/tls/certs/OktaOnPremScimServer-${CUSTOMER_ID}.crt         2>/dev/null || true
ln -s /opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-${CUSTOMER_ID}.key      /etc/pki/tls/private/OktaOnPremScimServer-${CUSTOMER_ID}.key       2>/dev/null || true
ln -s /opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-${CUSTOMER_ID}.p12      /etc/pki/tls/private/OktaOnPremScimServer-${CUSTOMER_ID}.p12       2>/dev/null || true
ln -s /opt/OktaOnPremScimServer/certs/OktaOnPremScimServer-${CUSTOMER_ID}.p12.pass /etc/pki/tls/private/OktaOnPremScimServer-${CUSTOMER_ID}.p12.pass  2>/dev/null || true

# Script extracted from the RPM %pre scriptlet for the Okta On-Prem SCIM Server, adapted for use in the Docker image entrypoint.
# This script is responsible for setting up the necessary system user/group, directories, permissions, and generating server certificates if they do not already exist.

# ---------------- directories & permissions ----------------
chmod 755 /etc/OktaOnPremScimServer /var/log/OktaOnPremScimServer
chown root:root /etc/OktaOnPremScimServer /var/log/OktaOnPremScimServer

# ---------- helpers ----------
log()  { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*"; }
fail() { echo "ERROR: $*" >&2; exit 1; }

# ---------- inputs ----------
CUSTOMER_ID="${CUSTOMER_ID:-}"
echo "CUSTOMER_ID during install/upgrade: ${CUSTOMER_ID}" >> /tmp/scim-customer-id.log
[ -n "${CUSTOMER_ID}" ] || fail "CUSTOMER_ID not provided!"

# ---------- prereqs ----------
command -v openssl >/dev/null 2>&1 || fail "openssl not found"
command -v keytool  >/dev/null 2>&1 || fail "keytool (from Java) not found"

# ---------- paths ----------
CERT_DIR="/etc/pki/tls/certs"
KEY_DIR="/etc/pki/tls/private"
APP_ETC="/etc/OktaOnPremScimServer"
LOG_DIR="/var/log/OktaOnPremScimServer"

CERT_FILE="${CERT_DIR}/OktaOnPremScimServer-${CUSTOMER_ID}.crt"
KEY_FILE="${KEY_DIR}/OktaOnPremScimServer-${CUSTOMER_ID}.key"
KEYSTORE_FILE="${KEY_DIR}/OktaOnPremScimServer-${CUSTOMER_ID}.p12"
KEYSTORE_PASS_FILE="${KEY_DIR}/OktaOnPremScimServer-${CUSTOMER_ID}.p12.pass"

CUSTOMER_PROPS_FILE="${APP_ETC}/config-${CUSTOMER_ID}.properties"
CUSTOMER_ID_CONF_FILE="${APP_ETC}/customer-id.conf"
JAVA_OPTS_CONF_FILE="${APP_ETC}/jvm.conf"

# ---------- dirs & perms ----------
mkdir -p "${CERT_DIR}" "${KEY_DIR}" "${APP_ETC}" "${LOG_DIR}"
chmod 755 "${CERT_DIR}" "${APP_ETC}" "${LOG_DIR}"

chmod 710 "${KEY_DIR}"
if command -v setfacl >/dev/null 2>&1; then
  setfacl -m u:okscimserver:x "${KEY_DIR}" || true
else
  chmod 751 "${KEY_DIR}"
fi
chown okscimserver:okscimserver "${LOG_DIR}"

# ---------- determine if first install based on file existence ----------
if [ -f "${CUSTOMER_PROPS_FILE}" ] && [ -f "${CUSTOMER_ID_CONF_FILE}" ] && [ -f "${KEY_FILE}" ] && [ -f "${CERT_FILE}" ] && [ -f "${KEYSTORE_FILE}" ] && [ -f "${KEYSTORE_PASS_FILE}" ]; then
  IS_FIRST_INSTALL="0"
  log "Existing certificates detected. Treating as upgrade/restart."
else
  IS_FIRST_INSTALL="1"
  log "No existing certificates found. Treating as first-time installation."
fi

# ---------- install vs upgrade ----------
if [ "${IS_FIRST_INSTALL}" = "1" ]; then
  log "First-time installation detected."
  log "Generating server keypair + self-signed cert for ${CUSTOMER_ID}"
  openssl genrsa -out "${KEY_FILE}" 4096

  HOST_DNS="${HOST_DNS:-$(hostname -f 2>/dev/null || hostname)}"
  if command -v ip >/dev/null 2>&1; then
    PRIMARY_IPV4="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')"
  fi
  [ -n "${PRIMARY_IPV4:-}" ] || PRIMARY_IPV4="$(hostname -I 2>/dev/null | awk '{print $1}')"

  SAN_LIST="DNS:localhost,IP:127.0.0.1,DNS:${HOST_DNS},DNS:${CUSTOMER_ID}.okta.com"
  [ -n "${PRIMARY_IPV4}" ] && SAN_LIST="${SAN_LIST},IP:${PRIMARY_IPV4}"
  CN="${HOST_DNS}"

  openssl req -new -x509 -key "${KEY_FILE}" -out "${CERT_FILE}" -days 3650 \
    -subj "/C=US/ST=CA/L=San Francisco/O=Okta/OU=OktaOnPremScimServer/CN=${CN}" \
    -addext "subjectAltName=${SAN_LIST}"

  openssl rand -base64 24 > "${KEYSTORE_PASS_FILE}"
  KEYSTORE_PASSWORD="$(tr -d '\n' < "${KEYSTORE_PASS_FILE}")"

  openssl pkcs12 -export -in "${CERT_FILE}" -inkey "${KEY_FILE}" \
    -out "${KEYSTORE_FILE}" -name "okscimservercert" -passout pass:"${KEYSTORE_PASSWORD}"

  chown root:root "${KEY_FILE}" "${CERT_FILE}" "${KEYSTORE_FILE}" "${KEYSTORE_PASS_FILE}"
  chmod 600 "${KEY_FILE}" "${KEYSTORE_FILE}" "${KEYSTORE_PASS_FILE}"
  chmod 644 "${CERT_FILE}"

  if command -v setfacl >/dev/null 2>&1; then
    setfacl -m u:okscimserver:r "${KEYSTORE_FILE}" "${KEYSTORE_PASS_FILE}" || true
  else
    chgrp okscimserver "${KEYSTORE_FILE}" "${KEYSTORE_PASS_FILE}" || true
    chmod 640 "${KEYSTORE_FILE}" "${KEYSTORE_PASS_FILE}" || true
  fi

  log "Server keystore created at ${KEYSTORE_FILE} (alias=okscimservercert)"
else
  log "Reusing existing server keystore and configs."
  if [ -f "${KEYSTORE_PASS_FILE}" ]; then
    KEYSTORE_PASSWORD="$(tr -d '\n' < "${KEYSTORE_PASS_FILE}")"
  else
    fail "Keystore password file not found during upgrade!"
  fi
fi

# ---------- app API key (fresh each install/upgrade) ----------
if [ -f "${CUSTOMER_PROPS_FILE}" ] && grep -q "^scim.security.bearer.token=" "${CUSTOMER_PROPS_FILE}"; then
  API_KEY="$(grep "^scim.security.bearer.token=" "${CUSTOMER_PROPS_FILE}" | cut -d'=' -f2)"
  log "Reusing existing API key from ${CUSTOMER_PROPS_FILE}"
else
  API_KEY="$(openssl rand -hex 16)"
  log "Generating new API key"
fi

# ---------- Spring Boot config ----------
log "Writing config: ${CUSTOMER_PROPS_FILE}"
cat > "${CUSTOMER_PROPS_FILE}" <<EOF
# HTTPS only
server.port=1443
server.servlet.context-path=/ws/rest
server.ssl.enabled=true

# Server certificate/keystore
server.ssl.key-store-type=PKCS12
server.ssl.key-store=${KEYSTORE_FILE}
server.ssl.key-store-password=${KEYSTORE_PASSWORD}
server.ssl.key-alias=okscimservercert

# Explicitly disable client-auth (no mTLS)
server.ssl.client-auth=NONE

# Set Header size
server.max-http-request-header-size=10KB

# Strong protocols
server.ssl.enabled-protocols=TLSv1.2,TLSv1.3

# App-layer auth
scim.security.bearer.token=${API_KEY}

# Hikari settings----
app.datasource.hikari.maximumPoolSize=10
app.datasource.hikari.minimumIdle=0
app.datasource.hikari.connectionTimeout=30000
app.datasource.hikari.validationTimeout=3000
app.datasource.hikari.idleTimeout=90000
app.datasource.hikari.keepaliveTime=60000
app.datasource.hikari.maxLifetime=180000
app.datasource.hikari.initializationFailTimeout=0

# Logging
# ==== Console OFF (file only) ====
logging.pattern.console=1

# ==== Levels ====
logging.level.root=${LOG_LEVEL_ROOT:-INFO}
logging.level.org.springframework.web=${LOG_LEVEL_SPRING_WEB:-WARN}
logging.level.org.apache.catalina=${LOG_LEVEL_CATALINA:-WARN}
logging.level.org.apache.coyote=${LOG_LEVEL_COYOTE:-ERROR}
logging.level.org.apache.tomcat=${LOG_LEVEL_TOMCAT:-ERROR}
logging.level.com.zaxxer.hikari=${LOG_LEVEL_HIKARI:-WARN}
logging.level.com.okta.server.scim=${LOG_LEVEL_OKTA_SCIM:-INFO}
logging.level.org.springframework.jdbc=${LOG_LEVEL_SPRING_JDBC:-INFO}

# ==== File pattern (rotated file logs) ====
logging.pattern.file=%d{yyyy-MM-dd'T'HH:mm:ss.SSSXXX}  [pid:\${PID:-unknown}] [%thread] %class{36}:%line - %msg%n
EOF
chown okscimserver:okscimserver "${CUSTOMER_PROPS_FILE}"
chmod 600 "${CUSTOMER_PROPS_FILE}"

# ---------- customer-id env ----------
echo "CUSTOMER_ID=${CUSTOMER_ID}" > "${CUSTOMER_ID_CONF_FILE}"
chown okscimserver:okscimserver "${CUSTOMER_ID_CONF_FILE}"
chmod 600 "${CUSTOMER_ID_CONF_FILE}"

# ---------- JVM options ----------
echo 'JAVA_OPTS="-Xms512m -Xmx4096m -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError"' > "${JAVA_OPTS_CONF_FILE}"
chown okscimserver:okscimserver "${JAVA_OPTS_CONF_FILE}"
chmod 600 "${JAVA_OPTS_CONF_FILE}"

# ---------- SELinux ----------
if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" = "Enforcing" ]; then
  restorecon -v "${KEY_FILE}" "${CERT_FILE}" "${KEYSTORE_FILE}" "${KEYSTORE_PASS_FILE}" || true
fi

# ----------------------------------------------------------------------------
# Start the SCIM Server  
echo ""
echo "################################################################"
echo ""
echo "🔐 SCIM Server Certificate (Public Key):"
echo ""
cat "${CERT_FILE}"
echo ""
echo ""
echo "🌐 Hostname:  $(hostname)"
echo "🔑 API Token: Bearer ${API_KEY}"
echo ""
echo "################################################################"
echo ""
echo "🚀 Starting the SCIM Server"
exec /opt/OktaOnPremScimServer/bin/OktaOnPremScimServer.sh 2>&1 &

tail -f /var/log/OktaOnPremScimServer/*.log
