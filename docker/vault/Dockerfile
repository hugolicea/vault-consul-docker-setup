FROM hashicorp/vault:1.18.0

# Install jq
RUN apk add --no-cache jq

# Copy the init-unseal script
COPY init-unseal.sh /vault/init-unseal.sh

# Make the script executable
RUN chmod +x /vault/init-unseal.sh