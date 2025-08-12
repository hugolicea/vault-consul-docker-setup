#!/bin/bash

# Create directory structure for Vault + Consul project
mkdir -p docker/vault/config
mkdir -p docker/vault/tls
mkdir -p docker/vault/policies
mkdir -p docker/consul/config
mkdir -p docker/consul/data

# Create empty configuration files
touch docker/vault/config/vault.hcl
touch docker/vault/init-unseal.sh
touch docker/consul/config/consul.hcl
touch docker-compose.yml

echo "[OK] Directory structure for Vault + Consul project created successfully."
read -p "Press any key to continue..."
