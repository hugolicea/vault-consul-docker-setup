#!/bin/bash

echo "=== Consul Data Persistence Test ==="

echo "1. Checking if Consul data directory exists and has content:"
if [ -d "./docker/consul/data" ]; then
    echo "✓ Consul data directory exists"
    echo "Contents:"
    ls -la ./docker/consul/data/
    if [ "$(ls -A ./docker/consul/data/)" ]; then
        echo "✓ Consul data directory has files"
    else
        echo "✗ Consul data directory is empty"
    fi
else
    echo "✗ Consul data directory missing"
    mkdir -p ./docker/consul/data
fi

echo -e "\n2. Checking if Vault data directory exists:"
if [ -d "./docker/vault/data" ]; then
    echo "✓ Vault data directory exists"
    echo "Contents:"
    ls -la ./docker/vault/data/
else
    echo "✗ Vault data directory missing"
    mkdir -p ./docker/vault/data
fi

echo -e "\n3. Checking Docker Compose volumes:"
echo "Consul volume mount: ./docker/consul/data:/consul/data"
echo "Vault volume mount: ./docker/vault/data:/vault/data"

echo -e "\n4. Testing sequence (run this on your staging server):"
echo "docker-compose down -v    # Stop and remove volumes"
echo "docker-compose up -d      # Start fresh"
echo "# Wait for initialization"
echo "docker-compose restart vault  # Should NOT create new token"
