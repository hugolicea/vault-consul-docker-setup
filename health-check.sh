#!/bin/bash

# Vault Health Monitor Script
# Use this for monitoring systems or cron jobs

VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
LOG_FILE="/var/log/vault-health.log"

# Try to create log file with proper permissions, fallback to local log
if ! touch "$LOG_FILE" 2>/dev/null; then
    LOG_FILE="./vault-health.log"
    echo "Warning: Cannot write to /var/log/, using local log file: $LOG_FILE" >&2
fi

# Function to log with timestamp
log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$message"
    echo "$message" >> "$LOG_FILE" 2>/dev/null || echo "$message" >> ./vault-health.log
}

# Check Vault status
check_vault() {
    if vault status > /dev/null 2>&1; then
        SEALED=$(vault status -format=json | jq -r '.sealed')
        INITIALIZED=$(vault status -format=json | jq -r '.initialized')

        if [ "$SEALED" = "false" ] && [ "$INITIALIZED" = "true" ]; then
            log "✅ Vault is healthy (unsealed and initialized)"
            return 0
        else
            log "⚠️ Vault issues: Sealed=$SEALED, Initialized=$INITIALIZED"
            return 1
        fi
    else
        log "❌ Vault is not accessible"
        return 1
    fi
}

# Check Consul status
check_consul() {
    if curl -s http://localhost:8500/v1/status/leader > /dev/null; then
        log "✅ Consul is healthy"
        return 0
    else
        log "❌ Consul is not accessible"
        return 1
    fi
}

# Main health check
main() {
    log "🔍 Starting health check..."

    VAULT_OK=0
    CONSUL_OK=0

    check_vault && VAULT_OK=1
    check_consul && CONSUL_OK=1

    if [ $VAULT_OK -eq 1 ] && [ $CONSUL_OK -eq 1 ]; then
        log "🎉 All services healthy"
        exit 0
    else
        log "💥 Some services have issues"
        exit 1
    fi
}

main "$@"
