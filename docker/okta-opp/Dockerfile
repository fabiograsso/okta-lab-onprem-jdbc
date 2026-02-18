FROM quay.io/centos/centos:stream9-minimal

LABEL maintainer="Fabio Gasso <iam@fabiograsso.net>"
LABEL org.opencontainers.image.authors="Fabio Gasso <iam@fabiograsso.net>"
LABEL org.opencontainers.image.title="Okta On-Prem Provisioning Agent"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/fabiograsso/okta-lab-onprem-jdbc"
LABEL org.opencontainers.image.description="Docker image for Okta On-Prem Provisioning Agent (OPP), designed for secure integration with Okta Identity Cloud."

ARG OKTA_EULA_ACCEPT=true

COPY packages/ /packages/

# Install necessary packages and update CA certificates if custom certificates are provided
RUN \
    shopt -s nullglob nocaseglob && \
    for cert in /packages/*.pem /packages/*.crt; do \
        if [ -f "$cert" ]; then \
            echo "🔐 Custom certificate found: $(basename "$cert"), updating CA trust..." && \
            cp -f "$cert" /etc/pki/ca-trust/source/anchors/ && \
            update-ca-trust && \
            echo "✅ CA trust updated successfully." || { \
                echo "❌ Failed to update CA trust with $cert"; \
                exit 1; \
            }; \
        fi; \
    done && \
    shopt -u nullglob nocaseglob && \
    microdnf install -y ca-certificates libXt openssl hostname procps && \
    microdnf clean all && \
    rm -rf /var/cache/yum /var/cache/dnf && \
    rm -rf /tmp/* /var/tmp/* && \
    find /var/cache -type f -delete

# Install Okta On-Prem Provisioning Agent 
RUN rpm -Uvh /packages/OktaProvisioningAgent*.rpm

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh && \
    rm -rf /packages/

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]