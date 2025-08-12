#!/bin/bash

echo "=== Vault/Consul Data Cleanup Script ==="

# Stop containers
echo "1. Stopping containers..."
docker-compose down

# Method 1: Try to remove files with docker
echo "2. Attempting to remove files using Docker..."
if docker run --rm -v $(pwd)/docker/vault/data:/data alpine sh -c "rm -f /data/*" 2>/dev/null; then
    echo "✓ Vault data files removed via Docker"
else
    echo "⚠ Could not remove vault files via Docker"
fi

if docker run --rm -v $(pwd)/docker/consul/data:/data alpine sh -c "rm -rf /data/*" 2>/dev/null; then
    echo "✓ Consul data files removed via Docker"
else
    echo "⚠ Could not remove consul files via Docker"
fi

# Method 2: Try with sudo if available
if command -v sudo >/dev/null 2>&1; then
    echo "3. Attempting to fix permissions with sudo..."
    sudo chown -R $(whoami):$(whoami) ./docker/vault/data/ ./docker/consul/data/ 2>/dev/null
    rm -rf ./docker/vault/data/* ./docker/consul/data/* 2>/dev/null
    echo "✓ Permissions fixed and files removed"
fi

# Recreate directories
echo "4. Recreating data directories..."
mkdir -p ./docker/vault/data ./docker/consul/data

# Set proper permissions
chmod 755 ./docker/vault/data ./docker/consul/data

echo "✓ Cleanup complete!"
echo ""
echo "Now run: docker-compose up --build -d"
