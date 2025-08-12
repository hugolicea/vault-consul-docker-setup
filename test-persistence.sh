#!/bin/bash

# Test Suite for Vault Backup and Health Check Scripts
# Run this script to test both backup-vault.sh and health-check.sh

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    case $1 in
        "PASS") echo -e "${GREEN}✅ PASS${NC}: $2" ;;
        "FAIL") echo -e "${RED}❌ FAIL${NC}: $2" ;;
        "INFO") echo -e "${YELLOW}ℹ️  INFO${NC}: $2" ;;
    esac
}

# Function to check if services are running
check_services() {
    if docker compose ps | grep -q "Up"; then
        return 0
    else
        return 1
    fi
}

# Function to wait for services
wait_for_services() {
    echo "⏳ Waiting for services to be ready..."
    sleep 10

    # Wait for Consul first
    for i in {1..12}; do
        if curl -s http://localhost:8500/v1/status/leader > /dev/null 2>&1; then
            print_status "PASS" "Consul is responding"
            break
        fi
        sleep 5
    done

    # Wait for Vault specifically
    for i in {1..12}; do
        if curl -s http://localhost:8200/v1/sys/health > /dev/null 2>&1; then
            print_status "PASS" "Vault is responding"
            break
        fi
        sleep 5
    done
}

echo "🧪 Starting Vault Test Suite..."
echo "================================"

# Ensure we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_status "FAIL" "Not in vault directory. Please cd to /opt/vault/docker-vault-consul"
    exit 1
fi

print_status "INFO" "Making scripts executable"
chmod +x backup-vault.sh health-check.sh

# Test 1: Services Status
echo ""
echo "📋 Test 1: Services Status Check"
echo "--------------------------------"
if check_services; then
    print_status "PASS" "Docker services are running"
else
    print_status "INFO" "Starting services..."
    docker compose up -d
    wait_for_services
fi

# Test 2: Health Check Script
echo ""
echo "🏥 Test 2: Health Check Script Tests"
echo "------------------------------------"

# Try to create log directory with proper permissions, or skip if not possible
if sudo mkdir -p /var/log 2>/dev/null && sudo touch /var/log/vault-health.log 2>/dev/null; then
    sudo chown $(whoami):$(whoami) /var/log/vault-health.log 2>/dev/null || true
    print_status "INFO" "Using system log file: /var/log/vault-health.log"
else
    print_status "INFO" "Using local log file: ./vault-health.log"
fi

export VAULT_ADDR="http://localhost:8200"

# Test normal operation
print_status "INFO" "Testing normal health check..."
if ./health-check.sh; then
    print_status "PASS" "Health check passed when services are up"
else
    print_status "FAIL" "Health check failed when services should be up"
fi

# Test Vault down scenario
print_status "INFO" "Testing Vault down scenario..."
docker compose stop vault
if ! ./health-check.sh; then
    print_status "PASS" "Health check correctly detected Vault down"
else
    print_status "FAIL" "Health check should have failed with Vault down"
fi

# Restart Vault
docker compose start vault
wait_for_services

# Test 3: Backup Script
echo ""
echo "💾 Test 3: Backup Script Tests"
echo "------------------------------"

# Setup backup directory
sudo mkdir -p /opt/vault/backups
sudo chown $(whoami):$(whoami) /opt/vault/backups

# Create test data
print_status "INFO" "Creating test data for backup..."
export VAULT_TOKEN=$(cat ./docker/vault/data/root_token.txt 2>/dev/null || echo "")

if [ -n "$VAULT_TOKEN" ]; then
    # Wait a bit more for Vault to be fully ready
    sleep 10

    # Try creating test data, ignore errors if Vault is still starting
    if vault kv put secret/test-backup timestamp="$(date)" test="backup-test" 2>/dev/null; then
        print_status "PASS" "Test data created successfully"
    else
        print_status "INFO" "Test data creation skipped (Vault may still be starting)"
    fi
else
    print_status "FAIL" "Could not get root token for test data creation"
fi

# Run backup
print_status "INFO" "Running backup script..."
if ./backup-vault.sh; then
    print_status "PASS" "Backup script executed successfully"

    # Verify backup file exists
    LATEST_BACKUP=$(ls -t /opt/vault/backups/vault_backup_*.tar.gz 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        print_status "PASS" "Backup file created: $(basename $LATEST_BACKUP)"

        # Test backup contents
        if tar -tzf "$LATEST_BACKUP" | grep -q "docker/vault/data"; then
            print_status "PASS" "Backup contains vault data"
        else
            print_status "FAIL" "Backup missing vault data"
        fi

        if tar -tzf "$LATEST_BACKUP" | grep -q "docker/consul/data"; then
            print_status "PASS" "Backup contains consul data"
        else
            print_status "FAIL" "Backup missing consul data"
        fi

    else
        print_status "FAIL" "No backup file found"
    fi
else
    print_status "FAIL" "Backup script failed"
fi

# Test 4: Log Analysis
echo ""
echo "📊 Test 4: Log Analysis"
echo "-----------------------"

# Check for log file in multiple locations
LOG_FOUND=false
if [ -f "/var/log/vault-health.log" ]; then
    LOG_FILE="/var/log/vault-health.log"
    LOG_FOUND=true
elif [ -f "./vault-health.log" ]; then
    LOG_FILE="./vault-health.log"
    LOG_FOUND=true
fi

if [ "$LOG_FOUND" = true ]; then
    LOG_LINES=$(wc -l < "$LOG_FILE")
    print_status "PASS" "Health log exists at $LOG_FILE with $LOG_LINES lines"

    echo "Recent log entries:"
    tail -5 "$LOG_FILE" | while read line; do
        echo "  $line"
    done
else
    print_status "FAIL" "No health log file found"
fi

# Test 5: Cleanup and Final Status
echo ""
echo "🧹 Test 5: Cleanup and Final Status"
echo "-----------------------------------"

# Ensure services are running after backup test
print_status "INFO" "Ensuring services are running after backup test..."
docker compose up -d
wait_for_services

# Final health check
if ./health-check.sh; then
    print_status "PASS" "Final health check passed"
else
    print_status "FAIL" "Final health check failed - services may need more time"
fi

# Show backup directory
if [ -d "/opt/vault/backups" ]; then
    BACKUP_COUNT=$(ls /opt/vault/backups/*.tar.gz 2>/dev/null | wc -l)
    print_status "INFO" "Found $BACKUP_COUNT backup files in /opt/vault/backups"
fi

echo ""
echo "🎉 Test Suite Complete!"
echo "======================="
print_status "INFO" "Check the output above for any failures"
print_status "INFO" "Health logs: /var/log/vault-health.log"
print_status "INFO" "Backups: /opt/vault/backups/"

echo ""
echo "📋 Manual Verification Steps:"
echo "1. Check backup file size: du -h /opt/vault/backups/*.tar.gz"
echo "2. Verify services: docker compose ps"
echo "3. Test restore procedure (in test environment only)"
echo "4. Set up cron jobs for production use"
