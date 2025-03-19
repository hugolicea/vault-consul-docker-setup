#!/bin/bash

export VAULT_ADDR=http://localhost:8200
export VAULT_SKIP_VERIFY=true

if vault status | grep -q "Initialized.*false"; then
  echo "[+] Initializing Vault..."
  INIT=$(vault operator init -format=json)
  if [ $? -ne 0 ]; then
    echo "[-] Failed to initialize Vault"
    exit 1
  fi
  echo "$INIT" > /vault/config/init.json

  UNSEAL_KEYS=$(echo $INIT | jq -r '.unseal_keys_b64[]')
  for key in $UNSEAL_KEYS; do
    vault operator unseal $key
    if [ $? -ne 0 ]; then
      echo "[-] Failed to unseal Vault with key $key"
      exit 1
    fi
  done

  ROOT_TOKEN=$(echo $INIT | jq -r '.root_token')
  echo "[+] Root Token: $ROOT_TOKEN"
  echo $ROOT_TOKEN > /vault/config/root_token.txt
else
  echo "[+] Vault already initialized"
  if vault status | grep -q "Sealed.*true"; then
    echo "[+] Vault is sealed. Unsealing..."
    UNSEAL_KEYS=$(jq -r '.unseal_keys_b64[]' /vault/config/init.json)
    for key in $UNSEAL_KEYS; do
      vault operator unseal $key
      if [ $? -ne 0 ]; then
        echo "[-] Failed to unseal Vault with key $key"
        exit 1
      fi
    done
    echo "[+] Vault unsealed successfully."
  else
    echo "[+] Vault is already unsealed."
  fi
fi