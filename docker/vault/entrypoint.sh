#!/bin/bash

# Make the init-unseal script executable
chmod +x /vault/init-unseal.sh

# Start the Vault server in the background
vault server -config=/vault/config/vault.hcl &

# Wait for the Vault server to be ready
while ! vault status >/dev/null 2>&1; do
  echo "Waiting for Vault to be ready..."
  sleep 2
done

# Run the init-unseal script
/vault/init-unseal.sh

# Keep the container running
wait