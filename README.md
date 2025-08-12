![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Version](https://img.shields.io/badge/version-v1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-blue)

# Vault + Consul Docker Setup

This repository provides a production-ready Docker-based setup for running HashiCorp Vault with Consul as the storage backend. It includes automated initialization, unsealing, and persistent storage to ensure Vault maintains its state across container restarts.

## Table of Contents

- [Vault + Consul Docker Setup](#vault--consul-docker-setup)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Prerequisites](#prerequisites)
  - [Quick Start](#quick-start)
    - [1. Clone the Repository](#1-clone-the-repository)
    - [2. Start the Services](#2-start-the-services)
    - [3. Access the Services](#3-access-the-services)
    - [4. Get Your Root Token](#4-get-your-root-token)
    - [5. Verify Setup](#5-verify-setup)
  - [Security Setup](#security-setup)
    - [Admin User Setup](#admin-user-setup)
    - [Using Admin Credentials](#using-admin-credentials)
    - [Root Token Management](#root-token-management)
  - [Operational Scripts](#operational-scripts)
    - [Health Monitoring](#health-monitoring)
    - [Backup Management](#backup-management)
    - [Testing Suite](#testing-suite)
    - [Automated Operations](#automated-operations)
  - [Architecture](#architecture)
    - [Project Structure](#project-structure)
  - [Configuration](#configuration)
    - [Vault Configuration (`docker/vault/config/vault.hcl`)](#vault-configuration-dockervaultconfigvaulthcl)
    - [Consul Configuration (`docker/consul/config/consul.hcl`)](#consul-configuration-dockerconsulconfigconsulhcl)
    - [Environment Variables](#environment-variables)
  - [Production Considerations](#production-considerations)
    - [Security Enhancements](#security-enhancements)
    - [Alternative Storage Backends](#alternative-storage-backends)
  - [Data Protection](#data-protection)
  - [Troubleshooting](#troubleshooting)
    - [Common Issues](#common-issues)
    - [Logs and Debugging](#logs-and-debugging)
  - [Secret Migration](#secret-migration)
    - [Export Secrets from Staging](#export-secrets-from-staging)
    - [Import to Production](#import-to-production)
    - [PowerShell Migration (Windows)](#powershell-migration-windows)
  - [Contributing](#contributing)
    - [Development Setup](#development-setup)
  - [License](#license)

## Features

- **🔐 Vault**: Secure secrets management and data encryption
- **🗄️ Consul Storage**: Reliable backend storage with data persistence
- **🚀 Automated Setup**: One-command deployment with automatic initialization
- **🔓 Auto-Unsealing**: Automatic unsealing on container restarts
- **📊 Management UIs**: Web interfaces for both Vault and Consul
- **🔄 State Persistence**: Root tokens and unseal keys persist across restarts
- **�️ Security Policies**: Role-based access control with admin user management
- **📈 Health Monitoring**: Automated health checks and logging
- **💾 Backup System**: Consistent backup creation and management
- **🧪 Test Suite**: Comprehensive testing for validation and troubleshooting
- **�🛠️ Development Ready**: Perfect for local development and testing

## Prerequisites

- [Docker](https://www.docker.com/) (v20.10 or later)
- [Docker Compose](https://docs.docker.com/compose/) (v2.0 or later)
- Basic understanding of HashiCorp Vault and Consul

## Quick Start

### 1. Clone the Repository

```sh
git clone https://github.com/hugolicea/vault-consul-docker-setup.git
cd vault-consul-docker-setup
```

### 2. Start the Services

```sh
# Start Vault and Consul
docker compose up --build -d

# Watch the initialization process
docker compose logs -f vault
```

### 3. Access the Services

- **Vault UI**: <http://localhost:8200>
- **Consul UI**: <http://localhost:8500>

### 4. Get Your Root Token

```sh
# The root token is automatically saved and displayed in logs
docker compose logs vault | grep "Root Token"

# Or retrieve it from the saved file
docker compose exec vault cat /vault/data/root_token.txt
```

### 5. Verify Setup

```sh
# Check Vault status
docker compose exec vault vault status

# Vault should show as "Initialized: true" and "Sealed: false"
```

## Security Setup

**⚠️ IMPORTANT**: After initial setup, follow these security best practices to secure your Vault deployment.

### Admin User Setup

Once Vault is running, create admin users instead of using the root token for daily operations:

```sh
# Navigate to your vault directory
cd /path/to/vault-consul-docker-setup

# Set Vault environment
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN=$(cat ./docker/vault/data/root_token.txt)

# Run the admin setup script
./setup-admin-users.sh
```

The setup script will:

- ✅ Create an admin policy with near-root privileges
- ✅ Enable userpass authentication
- ✅ Create an admin user with secure credentials
- ✅ Test the admin user login
- ✅ Save admin token for convenience

**What the admin policy allows:**

- Full access to secrets, policies, and auth methods
- Secret engine and auth method management
- Policy management

**What the admin policy restricts:**

- ❌ Root token generation (`sys/generate-root/*`)
- ❌ Direct unseal key access (`sys/unseal`)

### Using Admin Credentials

After setup, use admin credentials instead of root token:

```sh
# Login with admin user
export VAULT_ADDR="http://localhost:8200"
vault login -method=userpass username=your-admin-user

# Or use the saved admin token
export VAULT_TOKEN=$(cat ./docker/vault/data/admin_token.txt)
vault login -method=token
```

### Root Token Management

After confirming admin access works:

```sh
# Test admin access thoroughly first
vault secrets list
vault auth list
vault policy list

# Optional: Revoke root token (only if you're confident)
vault token revoke $(cat ./docker/vault/data/root_token.txt)
```

**🚨 WARNING**: Only revoke the root token after:

1. ✅ Testing admin user login works
2. ✅ Verifying admin can perform all needed operations
3. ✅ Backing up root token securely
4. ✅ Having emergency recovery procedures

For detailed security guidance, see [SECURITY.md](SECURITY.md).

## Operational Scripts

This setup includes several operational scripts for managing your Vault deployment:

### Health Monitoring

Monitor Vault and Consul health automatically:

```sh
# Run health check manually
./health-check.sh

# Check health logs
tail -f /var/log/vault-health.log
# or if local log is used:
tail -f ./vault-health.log
```

### Backup Management

Create consistent backups of your Vault data:

```sh
# Create backup manually
./backup-vault.sh

# List backups
ls -la /opt/vault/backups/

# Check backup contents
tar -tzf /opt/vault/backups/vault_backup_*.tar.gz | head -10
```

### Testing Suite

Run comprehensive tests to validate your setup:

```sh
# Run complete test suite
./test-persistence.sh

# This tests:
# ✅ Service health and status
# ✅ Health check script functionality
# ✅ Backup creation and restoration
# ✅ Log file creation and permissions
# ✅ Error scenario handling
```

### Automated Operations

Set up automated health monitoring and backups:

```sh
# Edit crontab for automated operations
crontab -e

# Add these lines:
# Health check every 5 minutes
*/5 * * * * /opt/vault/docker-vault-consul/health-check.sh

# Backup weekly on Sundays at 2 AM
0 2 * * 0 /opt/vault/docker-vault-consul/backup-vault.sh

# Cleanup old backups monthly
0 3 1 * * find /opt/vault/backups -name "vault_backup_*.tar.gz" -mtime +30 -delete
```

## Architecture

```text
┌─────────────────┐    ┌─────────────────┐
│     Vault       │    │     Consul      │
│   (Port 8200)   │◄──►│   (Port 8500)   │
│                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   Secrets   │ │    │ │   Storage   │ │
│ │ Management  │ │    │ │   Backend   │ │
│ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘
         │                       │
         └───── Persistent ──────┘
            Volume Storage
```

**Components:**

- **Vault Container**: Runs HashiCorp Vault server with automated init/unseal
- **Consul Container**: Provides persistent storage backend for Vault
- **Volume Mounts**: Ensure data persistence across container restarts
- **Auto-Init Script**: Handles initialization and unsealing automatically

### Project Structure

```text
vault-consul-docker-setup/
├── docker-compose.yml              # Service orchestration
├── setup-admin-users.sh            # Admin user creation script
├── backup-vault.sh                 # Backup creation script
├── health-check.sh                 # Health monitoring script
├── test-persistence.sh             # Comprehensive test suite
├── README.md                       # This documentation
├── SECURITY.md                     # Security best practices
├── docker/
│   ├── consul/
│   │   ├── config/consul.hcl       # Consul configuration
│   │   └── data/                   # Consul persistent data
│   └── vault/
│       ├── config/vault.hcl        # Vault configuration
│       ├── data/                   # Vault persistent data
│       ├── Dockerfile              # Custom Vault image
│       └── init-unseal.sh          # Vault initialization script
├── policies/                       # Vault access policies
│   ├── admin-policy.hcl
│   ├── developer-policy.hcl
│   └── production-operator-policy.hcl
├── logs/                          # Application logs
│   ├── vault/
│   └── consul/
└── docs/
    └── APPLICATION-INTEGRATION.md  # Integration examples
```

## Configuration

### Vault Configuration (`docker/vault/config/vault.hcl`)

```hcl
storage "consul" {
  address = "http://consul:8500"
  path    = "vault/"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = 1
}

ui = true
disable_mlock = true
api_addr = "http://vault:8200"
cluster_addr = "http://vault:8201"
```

### Consul Configuration (`docker/consul/config/consul.hcl`)

```hcl
datacenter = "dc1"
data_dir = "/consul/data"
bind_addr = "0.0.0.0"
server = true
bootstrap_expect = 1
log_level = "WARN"
ui_config {
  enabled = true
}
```

### Environment Variables

The setup uses the following environment variables:

- `VAULT_ADDR`: Vault server address (<http://localhost:8200>)
- `VAULT_SKIP_VERIFY`: Skip TLS verification (true for development)
- `CONSUL_LOG_LEVEL`: Consul logging level (WARN)

## Production Considerations

⚠️ **This setup is optimized for development and testing. For production use, consider:**

### Security Enhancements

1. **Enable TLS**:

   ```hcl
   listener "tcp" {
     address = "0.0.0.0:8200"
     tls_cert_file = "/vault/tls/server.crt"
     tls_key_file = "/vault/tls/server.key"
   }
   ```

2. **Auto-Unseal with Cloud KMS**:

   ```hcl
   seal "awskms" {
     region = "us-west-2"
     kms_key_id = "alias/vault-unseal"
   }
   ```

3. **High Availability**: Deploy multiple Vault and Consul nodes

4. **Network Security**: Use proper firewall rules and network segmentation

### Alternative Storage Backends

For production, consider:

- **Integrated Storage (Raft)**: Simpler, no external dependencies
- **Cloud Storage**: AWS DynamoDB, GCS, Azure Storage
- **Database**: PostgreSQL, MySQL (not recommended for high throughput)

## Data Protection

⚠️ **Critical: Protecting Your Vault Data**

Your Vault data is stored in local directories and contains all your secrets. Please review our comprehensive data protection guide:

📖 **[Data Protection Guide](DATA-PROTECTION.md)** - Essential reading for safe operations

Key points:

- **Safe Commands**: `docker compose logs`, `docker compose ps`, health checks
- **Dangerous Commands**: `docker compose down -v`, `docker system prune`, volume operations
- **Emergency Recovery**: Backup verification and restore procedures
- **Best Practices**: Regular backups, testing, monitoring

## Troubleshooting

### Common Issues

1. **Vault shows "Sealed" after restart**

   ```sh
   # Check if auto-unseal is working
   docker compose logs vault

   # Manual unseal if needed
   docker compose exec vault sh /vault/init-unseal.sh
   ```

2. **Permission denied errors**

   ```sh
   # Fix file permissions
   sudo chown -R $(whoami):$(whoami) ./docker/vault/data ./docker/consul/data
   ```

3. **Consul data not persisting**

   ```sh
   # Verify volume mounts
   docker compose exec consul ls -la /consul/data
   ```

4. **New root token generated on restart**

   ```sh
   # Check Consul connectivity from Vault
   docker compose exec vault curl http://consul:8500/v1/kv/vault/?keys
   ```

5. **Docker Compose command not found**

   ```sh
   # If using older Docker, try legacy command
   docker-compose --version

   # Or install Docker Compose v2
   sudo apt-get update && sudo apt-get install docker-compose-plugin
   ```

### Logs and Debugging

```sh
# View all logs
docker compose logs

# Follow specific service logs
docker compose logs -f vault
docker compose logs -f consul

# Check Vault status
docker compose exec vault vault status

# Check Consul cluster
docker compose exec consul consul members

# Run health check
./health-check.sh

# Run comprehensive tests
./test-persistence.sh
```

## Secret Migration

### Export Secrets from Staging

```bash
# Set source environment
export VAULT_ADDR="https://vault-staging.example.com:8200"
export VAULT_TOKEN="staging-token"

# Export secrets (requires jq)
vault kv get -format=json secret/myapp > staging-secrets.json
```

### Import to Production

```bash
# Set target environment
export VAULT_ADDR="https://vault-prod.example.com:8200"
export VAULT_TOKEN="prod-token"

# Import secrets
cat staging-secrets.json | jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"' | while read line; do
  key=$(echo $line | cut -d'=' -f1)
  value=$(echo $line | cut -d'=' -f2-)
  vault kv put secret/myapp $key="$value"
done
```

### PowerShell Migration (Windows)

```powershell
# Export from staging
$stagingHeaders = @{ "X-Vault-Token" = "staging-token" }
$secrets = Invoke-RestMethod -Uri "https://vault-staging:8200/v1/secret/data/myapp" -Headers $stagingHeaders

# Import to production
$prodHeaders = @{ "X-Vault-Token" = "prod-token" }
$body = @{ data = $secrets.data.data } | ConvertTo-Json
Invoke-RestMethod -Uri "https://vault-prod:8200/v1/secret/data/myapp" -Method PUT -Headers $prodHeaders -Body $body -ContentType "application/json"
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```sh
# Clone your fork
git clone https://github.com/yourusername/vault-consul-docker-setup.git

# Create feature branch
git checkout -b feature/your-feature

# Test your changes
docker compose up --build -d
docker compose logs -f

# Run test suite
./test-persistence.sh

# Clean up
docker compose down -v
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

**⭐ If this project helped you, please consider giving it a star!**

**🐛 Found a bug or have a suggestion? Please [open an issue](https://github.com/hugolicea/vault-consul-docker-setup/issues).**
