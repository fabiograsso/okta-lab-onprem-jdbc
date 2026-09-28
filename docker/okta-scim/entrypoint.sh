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
# legacy OPP Agent + On-Prem SCIM Server pair, there is no bearer token and
# no self-signed certificate to generate or upload as a Public Key.
# ----------------------------------------------------------------------------

APP_HOME="/opt/OktaOnPremSCIMAgent"
CONF_DIR="/opt/OktaOnPremSCIMAgent/config"
LOG_DIR="/opt/OktaOnPremSCIMAgent/logs"

log() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*"; }

mkdir -p "${CONF_DIR}" "${LOG_DIR}"
chmod 755 "${CONF_DIR}" "${LOG_DIR}"

# ---------- wait for OAuth device-code registration (make configure) ----------
log "👀 Checking agent registration status..."
while true; do
  if [ -f "${CONF_DIR}/agent-mode.conf" ]; then
    log "✅ Registration complete. Starting the On-Prem SCIM Agent..."
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
echo "################################################################"
echo ""
echo "🚀 Starting the On-Prem SCIM Agent"
echo ""

exec "${APP_HOME}/bin/OktaOnPremSCIMAgent.sh" 2>&1
