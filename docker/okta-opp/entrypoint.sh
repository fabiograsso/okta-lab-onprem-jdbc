#!/bin/bash
#
# Author: Fabio Grasso <iam@fabiograsso.net>
# Version: 1.0.0
# License: Apache-2.0
# Description: Entrypoint docker script to for the Okta OPP Agent
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

# Loop until both config files exist and contain the required keys
MAIN_CONF_FILE="/opt/OktaProvisioningAgent/conf/OktaProvisioningAgent.conf"
ADDITIONAL_CONF_FILE="/opt/OktaProvisioningAgent/conf/settings.conf"
KEYSTORE="/opt/OktaProvisioningAgent/security/OktaProvisioningKeystore.p12"

mkdir -p /opt/OktaProvisioningAgent/security
mkdir -p /opt/OktaProvisioningAgent/conf
mkdir -p /opt/OktaProvisioningAgent/logs
touch /opt/OktaProvisioningAgent/conf/settings.conf
touch /opt/OktaProvisioningAgent/logs/agent.log
sed -i 's/^JAVA_OPTS=.*/JAVA_OPTS="-Xmx4096m -Dhttps.protocols=TLSv1.2"/' /opt/OktaProvisioningAgent/conf/settings.conf
chown -R provisioningagent:provisioningagent /opt/OktaProvisioningAgent
chmod +x /opt/OktaProvisioningAgent/jre/bin/*

echo "👀 Checking configuration files..."
while true; do
	if [[ -f "$MAIN_CONF_FILE" && -f "$ADDITIONAL_CONF_FILE" && -f "$KEYSTORE" ]] &&
		grep -qE "^orgUrl =" "$MAIN_CONF_FILE" &&
		grep -qE "^agentId = " "$MAIN_CONF_FILE" &&
		grep -qE "^keystoreKey = " "$MAIN_CONF_FILE" &&
		grep -qE "^keyPassword = " "$MAIN_CONF_FILE" &&
		grep -qE "^env = " "$MAIN_CONF_FILE" &&
		grep -qE "^subdomain = " "$MAIN_CONF_FILE" &&
		grep -qE "^agentKey = " "$MAIN_CONF_FILE"; then
		echo "✅ Configuration files are ready. Starting the OPP Agent..."
		break
	fi
	echo "⏳ Waiting for configuration files. Please configure the Agent..."
	sleep 10
done

# ----------------------------------------------------------------------------

# Start the OPP Agent 
echo "🚀 Starting the OPP Agent"
exec /opt/OktaProvisioningAgent/OktaProvisioningAgent 2>&1