#!/bin/sh

export VAULT_ADDR=http://localhost:8200
export VAULT_SKIP_VERIFY=true

# Give Vault a moment to fully start
sleep 3

echo "[+] Checking Vault status..."

# Check if this is a repeat initialization (debugging)
if [ -f "/vault/data/init.json" ]; then
  echo "[!] WARNING: Found existing init.json file"
  echo "[!] This suggests either:"
  echo "[!] 1. Consul data is not persisting"
  echo "[!] 2. Vault is connecting to wrong Consul"
  echo "[!] 3. Consul cluster is being reset"

  # Show some debug info
  echo "[DEBUG] Checking Consul connectivity..."
  if command -v curl >/dev/null 2>&1; then
    echo "[DEBUG] Consul leader: $(curl -s http://consul:8500/v1/status/leader 2>/dev/null || echo 'Cannot reach Consul')"
    echo "[DEBUG] Consul vault keys: $(curl -s http://consul:8500/v1/kv/vault/?keys 2>/dev/null || echo 'No vault keys in Consul')"
    echo "[DEBUG] Checking vault data specifically:"
    curl -s http://consul:8500/v1/kv/vault/core/cluster/local/info 2>/dev/null || echo "[DEBUG] No vault cluster info in Consul"
    curl -s http://consul:8500/v1/kv/vault/core/keyring 2>/dev/null || echo "[DEBUG] No vault keyring in Consul"
  fi
fi

# Get current Vault status
VAULT_STATUS=$(vault status 2>&1)
echo "[+] Current Vault status: $VAULT_STATUS"

# Check if Vault is actually initialized (regardless of local files)
if echo "$VAULT_STATUS" | grep -q "Initialized.*false" || echo "$VAULT_STATUS" | grep -q "not initialized"; then
  echo "[+] Vault is not initialized. Initializing now..."

  # Remove old initialization files if they exist (they're invalid)
  if [ -f "/vault/data/init.json" ]; then
    echo "[+] Removing old initialization files..."
    rm -f /vault/data/init.json /vault/data/root_token.txt
  fi

  # Initialize Vault
  INIT=$(vault operator init -format=json)
  if [ $? -ne 0 ]; then
    echo "[-] Failed to initialize Vault"
    exit 1
  fi

  # Save initialization data
  echo "$INIT" > /vault/data/init.json
  echo "[+] Saved initialization data to /vault/data/init.json"

  # Unseal with the new keys
  UNSEAL_KEYS=$(echo $INIT | jq -r '.unseal_keys_b64[]')
  for key in $UNSEAL_KEYS; do
    vault operator unseal $key
    if [ $? -ne 0 ]; then
      echo "[-] Failed to unseal Vault with key $key"
      exit 1
    fi
  done

  # Save root token
  ROOT_TOKEN=$(echo $INIT | jq -r '.root_token')
  echo "[+] Root Token: $ROOT_TOKEN"
  echo $ROOT_TOKEN > /vault/data/root_token.txt
  echo "[+] Saved root token to /vault/data/root_token.txt"

elif echo "$VAULT_STATUS" | grep -q "Sealed.*true"; then
  echo "[+] Vault is initialized but sealed. Checking for existing keys..."

  if [ -f "/vault/data/init.json" ]; then
    echo "[+] Found existing initialization files. Attempting to unseal..."
    UNSEAL_KEYS=$(jq -r '.unseal_keys_b64[]' /vault/data/init.json)

    # Test if the first key works (to verify the keys are valid)
    FIRST_KEY=$(echo "$UNSEAL_KEYS" | head -n1)
    TEST_UNSEAL=$(vault operator unseal $FIRST_KEY 2>&1)

    if echo "$TEST_UNSEAL" | grep -q "not initialized"; then
      echo "[-] Local keys don't match Vault state. Vault appears uninitialized."
      echo "[-] Removing invalid local files and re-initializing..."
      rm -f /vault/data/init.json /vault/data/root_token.txt

      # Re-run initialization
      exec /vault/init-unseal.sh
    else
      # Keys work, continue unsealing with remaining keys
      echo "[+] Keys are valid. Continuing unseal process..."
      for key in $UNSEAL_KEYS; do
        vault operator unseal $key >/dev/null 2>&1
        if [ $? -eq 0 ]; then
          echo "[+] Unsealed with key"
        fi
      done
      echo "[+] Vault unsealed successfully."
    fi
  else
    echo "[-] Vault is sealed but no local initialization files found"
    echo "[-] Cannot unseal without keys. Manual intervention required."
    exit 1
  fi

else
  echo "[+] Vault is already unsealed and ready."
fi

echo "[+] Initialization script completed"