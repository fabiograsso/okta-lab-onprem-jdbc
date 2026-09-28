FROM quay.io/centos/centos:stream9-minimal

LABEL maintainer="Fabio Gasso <iam@fabiograsso.net>"
LABEL org.opencontainers.image.authors="Fabio Gasso <iam@fabiograsso.net>"
LABEL org.opencontainers.image.title="Okta On-Prem SCIM Agent"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/fabiograsso/okta-lab-onprem-jdbc-v2"
LABEL org.opencontainers.image.description="Docker image for Okta On-Prem SCIM Agent, designed for secure integration with Okta Identity Cloud."

COPY packages/ /packages/

# Update CA trust if custom certificates are provided in the /packages directory
RUN for cert in /packages/*.pem /packages/*.crt; do \
        if [ -f "$cert" ]; then \
            echo "🔐 Custom certificate found: $(basename "$cert"), updating CA trust..." && \
            cp -f "$cert" /etc/pki/ca-trust/source/anchors/ && \
            update-ca-trust && \
            echo "✅ CA trust updated successfully." || { \
                echo "❌ Failed to update CA trust with $cert"; \
                exit 1; \
            }; \
        fi; \
    done

# Install necessary packages and update CA certificates if custom certificates are provided
RUN \
    microdnf update -y && \
    microdnf install -y ca-certificates libXt openssl hostname procps java-25-openjdk-headless && \ 
    mkdir -p /packages/ && \
    shopt -s nullglob nocaseglob && \
    microdnf clean all && \
    rm -rf /var/cache/yum /var/cache/dnf && \
    rm -rf /tmp/* /var/tmp/* && \
    find /var/cache -type f -delete

# Install Okta On-Prem SCIM Agent
# Note: the RPM package itself is still named OktaOnPremScimServer-<version>.rpm
# (per Okta Admin Console "Add agent" install instructions), even though it
# installs into /opt/OktaOnPremSCIMAgent/. INSTALL_MODE=agent selects the new
# consolidated agent install mode (replaces the old CUSTOMER_ID/OKTA_EULA_ACCEPT
# install-time vars and self-signed cert generation - registration is now done
# via OAuth device-code flow through configure_agent.sh at runtime).
RUN INSTALL_MODE=agent rpm -Uvh /packages/OktaOnPremScimServer-*.rpm && \
    rm -rf /etc/OktaOnPremSCIMAgent/* && \
    rm -rf /var/log/OktaOnPremSCIMAgent/*

# Download MySQL Connector/J
ARG MYSQL_CONNECTOR_VERSION=9.6.0
RUN curl -L -o /packages/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.jar \
    "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${MYSQL_CONNECTOR_VERSION}/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.jar" && \
    echo "Downloaded MySQL Connector/J ${MYSQL_CONNECTOR_VERSION}" && \
    echo "License: GPL v2 with Universal FOSS Exception" && \
    echo "https://oss.oracle.com/licenses/universal-foss-exception/" && \
    cp -fr /packages/*.jar /opt/OktaOnPremSCIMAgent/userlib/ && \
    rm -rf /packages/

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

# Bearer-token auth and the self-signed cert are gone in the new consolidated
# agent (registration is OAuth device-code based - see entrypoint.sh), so the
# healthcheck no longer needs a token or CA cert.
# TODO: verify the exact status endpoint/response text against the real agent.
HEALTHCHECK --start-period=30s --start-interval=1s --interval=300s --timeout=5s \
  CMD curl -k -s -f --max-time 5 --http1.0 https://localhost:1443/ws/rest/jdbc_on_prem/scim/v2/Status 2>/dev/null | grep -q 'running' || exit 1
