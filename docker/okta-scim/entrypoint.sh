#!/bin/bash
#
# Author: Fabio Grasso <iam@fabiograsso.net>
# Version: 2.0.0
# License: Apache-2.0
# Description: Entrypoint docker script for the Okta On-Prem SCIM Agent
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

# ----------------------------------------------------------------------------
# NOTE (2026.09.0 consolidation): the new Okta On-Prem SCIM Agent registers
# with Okta via an OAuth device-code flow (org URL + browser-approved code),
# run interactively via `make configure` -> configure_agent.sh. Unlike the
# legacy On-Prem SCIM Server, there is no bearer token and no Public Key to
# upload in the Okta Admin Console.
#
# The agent's own HTTPS listener (used for the DB-facing SCIM endpoint) still
# needs a TLS certificate though, so this entrypoint still generates a
# self-signed cert/keystore locally - it's just no longer uploaded anywhere.
#
# TODO: confirm the exact registration marker file(s) written by
# configure_agent.sh (used below to detect "already configured"), the real
# config/cert file paths and property names, and the real start command/
# binary - all are best-effort guesses based on the legacy layout, adapted
# for a non-systemd container. Verify once the real RPM is tested.
# ----------------------------------------------------------------------------

APP_HOME="/opt/OktaOnPremSCIMAgent"
CONF_DIR="/etc/OktaOnPremSCIMAgent"
LOG_DIR="/var/log/OktaOnPremSCIMAgent"
# Certs live under CONF_DIR (already bind-mounted to the host) so they
# persist across container restarts without needing a dedicated volume mount.
CERT_DIR="${CONF_DIR}/certs"

log()  { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*"; }
fail() { echo "ERROR: $*" >&2; exit 1; }

mkdir -p "${CONF_DIR}" "${LOG_DIR}" "${CERT_DIR}"
chmod 755 "${CONF_DIR}" "${LOG_DIR}"
chmod 710 "${CERT_DIR}"

# ---------- local TLS cert/keystore for the agent's HTTPS listener ----------
CERT_FILE="${CERT_DIR}/OktaOnPremSCIMAgent.crt"
KEY_FILE="${CERT_DIR}/OktaOnPremSCIMAgent.key"
KEYSTORE_FILE="${CERT_DIR}/OktaOnPremSCIMAgent.p12"
KEYSTORE_PASS_FILE="${CERT_DIR}/OktaOnPremSCIMAgent.p12.pass"

if [ -f "${CERT_FILE}" ] && [ -f "${KEY_FILE}" ] && [ -f "${KEYSTORE_FILE}" ] && [ -f "${KEYSTORE_PASS_FILE}" ]; then
  log "Existing self-signed certificate found. Reusing it."
else
  log "Generating self-signed certificate for the agent's HTTPS listener..."
  command -v openssl >/dev/null 2>&1 || fail "openssl not found"

  openssl genrsa -out "${KEY_FILE}" 4096

  HOST_DNS="${HOST_DNS:-$(hostname -f 2>/dev/null || hostname)}"
  if command -v ip >/dev/null 2>&1; then
    PRIMARY_IPV4="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')"
  fi
  [ -n "${PRIMARY_IPV4:-}" ] || PRIMARY_IPV4="$(hostname -I 2>/dev/null | awk '{print $1}')"

  SAN_LIST="DNS:localhost,IP:127.0.0.1,DNS:${HOST_DNS}"
  [ -n "${PRIMARY_IPV4}" ] && SAN_LIST="${SAN_LIST},IP:${PRIMARY_IPV4}"

  openssl req -new -x509 -key "${KEY_FILE}" -out "${CERT_FILE}" -days 3650 \
    -subj "/C=US/ST=CA/L=San Francisco/O=Okta/OU=OktaOnPremSCIMAgent/CN=${HOST_DNS}" \
    -addext "subjectAltName=${SAN_LIST}"

  openssl rand -base64 24 > "${KEYSTORE_PASS_FILE}"
  KEYSTORE_PASSWORD="$(tr -d '\n' < "${KEYSTORE_PASS_FILE}")"

  openssl pkcs12 -export -in "${CERT_FILE}" -inkey "${KEY_FILE}" \
    -out "${KEYSTORE_FILE}" -name "okscimagentcert" -passout pass:"${KEYSTORE_PASSWORD}"

  chmod 600 "${KEY_FILE}" "${KEYSTORE_FILE}" "${KEYSTORE_PASS_FILE}"
  chmod 644 "${CERT_FILE}"

  log "Self-signed certificate created at ${CERT_FILE}"
fi

# ---------- wait for OAuth device-code registration (make configure) ----------
log "👀 Checking agent registration status..."
while true; do
  # TODO: replace this glob with the actual registration marker file(s)
  # written by configure_agent.sh once confirmed against the real RPM.
  if ls "${CONF_DIR}"/*.conf >/dev/null 2>&1 || ls "${APP_HOME}"/conf/*.conf >/dev/null 2>&1; then
    log "✅ Registration files found. Starting the On-Prem SCIM Agent..."
    break
  fi
  log "⏳ Waiting for agent registration. Run 'make configure' to register with your Okta org..."
  sleep 10
done

echo ""
echo "################################################################"
echo ""
echo "🌐 Hostname: $(hostname)"
echo ""
echo "🔐 Self-signed certificate (for reference, not uploaded to Okta):"
echo ""
cat "${CERT_FILE}"
echo ""
echo "################################################################"
echo ""
echo "🚀 Starting the On-Prem SCIM Agent"
# TODO: verify this binary/script path and name against the real
# OktaOnPremSCIMAgent RPM contents once available.
exec "${APP_HOME}/bin/OktaOnPremSCIMAgent" 2>&1
