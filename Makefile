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
	@echo ""
	@echo "--> Checking prerequisites..."
	@if ! ls ./docker/okta-opp/packages/OktaProvisioningAgent-*.rpm 1>/dev/null 2>&1; then \
		echo "\033[0;31m  [x] ERROR: Okta Provisioning Agent RPM not found!\033[0m"; \
		echo "Please place the OktaProvisioningAgent-*.rpm file in the './docker/okta-opp/packages/' directory."; \
		exit 1; \
	else \
		echo "\033[0;32m  [✔] Okta Provisioning Agent RPM found\033[0m"; \
	fi
	@if ! ls ./docker/okta-scim/packages/OktaOnPremScimServer-*.rpm 1>/dev/null 2>&1; then \
		echo "\033[0;31m  [x] ERROR: Okta SCIM Server RPM not found!\033[0m"; \
		echo "Please place the OktaOnPremScimServer-*.rpm file in the './docker/okta-scim/packages/' directory."; \
		exit 1; \
	else \
		echo "\033[0;32m  [✔] Okta SCIM Server RPM found\033[0m"; \
	fi
	@if ! ls ./docker/okta-scim/packages/*.jar 1>/dev/null 2>&1; then \
		echo "\033[0;33m  [i] INFO: JDBC driver JAR files not found!\033[0m The MySQL JDBC driver will be downloaded automatically during build."; \
	else \
		echo "\033[0;32m  [✔] JDBC driver JAR files found\033[0m"; \
	fi
	@if [ -z "$$(find ./docker/okta-opp/packages ./docker/okta-scim/packages -type f \( -name '*.pem' -o -name '*.crt' \) 2>/dev/null)" ]; then \
		echo "\033[0;33m  [i] INFO: No certificate files (.pem/.crt) found!\033[0m The containers may not work with custom VPN."; \
	else \
		echo "\033[0;32m  [✔] Certificate files found\033[0m"; \
	fi
	@echo "\033[0;32m[✔] All prerequisites check passed\033[0m"
	@echo ""