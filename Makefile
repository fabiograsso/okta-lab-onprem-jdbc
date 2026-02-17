# Makefile for managing the Okta OPP JDBC Docker environment
-include .env
export

.PHONY: help start start-logs stop stop-logs restart restart-logs logs build configure check-prereqs

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  start  		- Checks prerequisites, starts containers in the background."
	@echo "  stop           - Stops and removes all containers."
	@echo "  restart        - Restarts containers in the background."
	@echo "  logs           - Follows container logs."
	@echo "  start-logs     - Checks prerequisites, starts containers in the background, and follows logs."
	@echo "  start-live     - Checks prerequisites, starts containers in live mode"
	@echo "  restart-logs   - Restarts containers in the background and follows logs."
	@echo "  build          - Build all the images."
	@echo "  rebuild        - Forces a rebuild of the images from scratch."
	@echo "  kill           - Kill the containers and remove orphans"
	@echo "  configure      - Runs the interactive Okta agent configuration script."
	@echo "  check-prereqs  - Runs prerequisite checks without starting the services."

start: check-prereqs
	@echo "--> Starting containers in detached mode..."
	@docker compose up -d

start-live: check-prereqs
	@echo "--> Starting containers in detached mode..."
	@docker compose up

stop:
	@echo "--> Stopping containers..."
	@docker compose down

restart: stop start

logs:
	@echo "--> Tailing and following logs..."
	@docker compose logs -f --tail=500

start-logs: check-prereqs
	@echo "--> Starting containers and attaching logs..."
	@docker compose up -d &
	@sleep 5
	@$(MAKE) logs

restart-logs: stop start-logs

rebuild: check-prereqs
	@echo "--> Forcing a rebuild of all images..."
	@docker compose build --no-cache --pull --force-rm

build: check-prereqs
	@echo "--> Build all images..."
	@docker compose build

kill:
	@echo "--> Killing the containers and remove orphans"
	@docker compose kill --remove-orphans

configure:
	@echo "--> Launching Okta agent configuration script..."
	@docker compose exec okta-opp /opt/OktaProvisioningAgent/configure_agent.sh

check-prereqs:
	@echo "--> Checking prerequisites..."
	@# For rebuild, we check for RPMs and JDBC drivers (certificates are optional)
	@if ! ls ./docker/okta-opp/packages/OktaProvisioningAgent-*.rpm 1>/dev/null 2>&1; then \
		echo "\033[0;31mERROR: Okta Provisioning Agent RPM not found!\033[0m"; \
		echo "Please place the OktaProvisioningAgent-*.rpm file in the './packages/' directory."; \
		exit 1; \
	fi
	@if ! ls ./docker/okta-scim/packages/OktaOnPremScimServer-*.rpm 1>/dev/null 2>&1; then \
		echo "\033[0;31mERROR: Okta SCIM Server RPM not found!\033[0m"; \
		echo "Please place the OktaOnPremScimServer-*.rpm file in the './packages/' directory."; \
		exit 1; \
	fi
	@if ! ls ./docker/okta-scim/packages/*.jar 1>/dev/null 2>&1; then \
		echo "\033[0;31mERROR: JDBC driver JAR files not found!\033[0m"; \
		echo "Please place JDBC driver .jar files in the './packages/' directory."; \
		exit 1; \
	fi
	@if ! ls ./docker/okta-scim/packages/*.pem 1>/dev/null 2>&1; then \
		echo "\033[0;33mWARNING: No certificate file (.pem) found.\033[0m"; \
		echo "The container will work without custom certificates but may not work with custom VPN."; \
	fi
	@echo "  [✔] Build prerequisites check passed."
