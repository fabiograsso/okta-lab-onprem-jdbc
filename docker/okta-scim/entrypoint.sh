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
# legacy On-Prem SCIM Server, there is no self-signed certificate to
# generate, no bearer token, and no Public Key to upload in the Okta Admin
# Console - none of these appear anywhere in the new "Add agent" /
# provisioning setup flow. This entrypoint therefore only prepares
# directories/permissions and waits for registration before starting the
# agent.
#
# TODO: confirm the exact marker file(s) written by configure_agent.sh once
# registration completes (used below to detect "already configured"), and
# confirm the real start command/binary - both are best-effort guesses based
# on the legacy layout and Okta's own "systemctl restart
# OktaOnPremSCIMAgent.service" reference, adapted for a non-systemd container.
# ----------------------------------------------------------------------------

APP_HOME="/opt/OktaOnPremSCIMAgent"
CONF_DIR="/etc/OktaOnPremSCIMAgent"
LOG_DIR="/var/log/OktaOnPremSCIMAgent"

mkdir -p "${CONF_DIR}" "${LOG_DIR}"
chmod 755 "${CONF_DIR}" "${LOG_DIR}"

log() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*"; }

log "👀 Checking agent registration status..."
while true; do
  # TODO: replace this glob with the actual registration marker file(s)
  # written by configure_agent.sh (e.g. a credentials/registration conf
  # under ${CONF_DIR} or ${APP_HOME}/conf) once confirmed against the real
  # RPM.
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
echo "################################################################"
echo ""
echo "🚀 Starting the On-Prem SCIM Agent"
# TODO: verify this binary/script path and name against the real
# OktaOnPremSCIMAgent RPM contents once available.
exec "${APP_HOME}/bin/OktaOnPremSCIMAgent" 2>&1
