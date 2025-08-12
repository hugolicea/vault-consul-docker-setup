#!/bin/bash

# Vault Backup Script
# Run this regularly to backup Vault data

set -e

BACKUP_DIR="/opt/vault/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="vault_backup_${DATE}.tar.gz"

echo "🔄 Starting Vault backup process..."

# Create backup directory
mkdir -p $BACKUP_DIR

# Stop services for consistent backup
echo "⏸️ Stopping services for consistent backup..."
docker compose stop

# Create compressed backup of data directories (with sudo for permissions)
echo "📦 Creating backup archive..."
sudo tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" \
    ./docker/consul/data \
    ./docker/vault/data \
    ./policies \
    ./docker-compose.yml \
    ./*.sh \
    ./*.md

# Change ownership of backup file to current user
sudo chown $(whoami):$(whoami) "${BACKUP_DIR}/${BACKUP_FILE}"

# Restart services
echo "▶️ Restarting services..."
docker compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 30

# Verify Vault is accessible
if vault status > /dev/null 2>&1; then
    echo "✅ Backup completed successfully: ${BACKUP_FILE}"
    echo "📁 Backup location: ${BACKUP_DIR}/${BACKUP_FILE}"
else
    echo "❌ Warning: Vault might not be ready yet"
fi

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "vault_backup_*.tar.gz" -mtime +7 -delete

echo "🎉 Backup process completed!"
