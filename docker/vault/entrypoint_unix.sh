#!/bin/bash

# Make the init-unseal script executable
chmod +x /vault/init-unseal.sh

# Start the Vault server in the background
vault server -config=/vault/config/vault.hcl &
VAULT_PID=$!

# Wait for the Vault server to start listening (not ready, just listening)
echo "[+] Waiting for Vault server to start listening..."
while ! nc -z localhost 8200 2>/dev/null; do
  echo "Waiting for Vault to start listening on port 8200..."
  sleep 2
done

echo "[+] Vault server is listening, running initialization script..."
# Run the init-unseal script
/vault/init-unseal.sh

# Keep the container running by waiting for the Vault process
wait $VAULT_PID
