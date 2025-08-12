# Data Protection Guide

## Overview

This guide explains how to protect your Vault data from accidental deletion and provides recovery procedures.

## 🚨 **DANGEROUS Commands (Will Delete Data)**

### **Docker Compose Commands:**

```bash
# ❌ DESTROYS ALL DATA - removes volumes
docker compose down -v
docker compose down --volumes

# ❌ DESTROYS ALL DATA - removes everything
docker compose down --remove-orphans --volumes

# ❌ DELETES IMAGES AND DATA
docker system prune -a --volumes
```

### **Manual Directory Deletion:**

```bash
# ❌ DESTROYS ALL VAULT DATA
rm -rf ./docker/vault/data/
sudo rm -rf ./docker/vault/data/*

# ❌ DESTROYS ALL CONSUL DATA
rm -rf ./docker/consul/data/
sudo rm -rf ./docker/consul/data/*

# ❌ DESTROYS EVERYTHING
rm -rf ./docker/
```

### **Docker Volume Commands:**

```bash
# ❌ LISTS VOLUMES (safe to run)
docker volume ls

# ❌ DESTROYS ALL UNUSED VOLUMES
docker volume prune

# ❌ DESTROYS SPECIFIC VOLUME
docker volume rm vault-data
```

## ✅ **SAFE Commands (Data Preserved)**

### **Safe Docker Compose Commands:**

```bash
# ✅ SAFE - stops services, keeps data
docker compose stop
docker compose down

# ✅ SAFE - restarts services, keeps data
docker compose restart
docker compose up -d

# ✅ SAFE - rebuilds images, keeps data
docker compose up --build -d

# ✅ SAFE - shows status
docker compose ps
docker compose logs
```

### **Safe Docker Commands:**

```bash
# ✅ SAFE - shows containers
docker ps -a

# ✅ SAFE - shows images
docker images

# ✅ SAFE - removes unused containers/networks (NOT volumes)
docker system prune

# ✅ SAFE - removes unused images
docker image prune
```

## 🛡️ **How Your Data Is Protected**

### **Volume Mounts in docker-compose.yml:**

```yaml
volumes:
  - ./docker/consul/data:/consul/data # Host directory mapping
  - ./docker/vault/data:/vault/data # Host directory mapping
```

**What this means:**

- Data lives in `./docker/vault/data/` and `./docker/consul/data/` on your host
- Even if containers are deleted, data remains in these directories
- Only `-v` or `--volumes` flags can destroy this data

### **Critical Files That Store Your Data:**

```bash
# Your root token and unseal keys
./docker/vault/data/root_token.txt
./docker/vault/data/unseal_keys.txt

# Consul's database (your secrets are here)
./docker/consul/data/raft/raft.db
./docker/consul/data/node-id
./docker/consul/data/server_metadata.json
```

## 📋 **Safe Maintenance Commands**

### **Safe Restart Sequence:**

```bash
# Stop services
docker compose stop

# Start services
docker compose up -d

# Or combined restart
docker compose restart
```

### **Safe Updates:**

```bash
# Update and rebuild images, keep data
docker compose down
docker compose pull
docker compose up --build -d
```

### **Safe Cleanup:**

```bash
# Remove unused containers and networks (keeps volumes)
docker system prune

# Remove unused images
docker image prune

# Check disk usage
docker system df
```

## 🆘 **Emergency Data Recovery**

### **If You Accidentally Run `docker compose down -v`:**

**Immediate Actions:**

1. **STOP** - Don't run any more commands

2. **Check if data directories still exist:**

   ```bash
   ls -la ./docker/vault/data/
   ls -la ./docker/consul/data/
   ```

3. **If directories are empty, check backups:**

   ```bash
   ls -la /opt/vault/backups/
   ```

4. **Restore from backup:**

   ```bash
   # Stop services
   docker compose down

   # Restore from latest backup
   cd /tmp
   tar -xzf /opt/vault/backups/vault_backup_*.tar.gz
   sudo cp -r docker/vault/data/* /opt/vault/docker-vault-consul/docker/vault/data/
   sudo cp -r docker/consul/data/* /opt/vault/docker-vault-consul/docker/consul/data/

   # Restart services
   cd /opt/vault/docker-vault-consul
   docker compose up -d
   ```

## 🔒 **Best Practices to Protect Data**

### **1. Always Use Safe Commands:**

```bash
# Instead of: docker compose down -v
# Use: docker compose down

# Instead of: rm -rf ./docker/
# Use: Specific file cleanup only
```

### **2. Regular Backups:**

```bash
# Run backup before major changes
./backup-vault.sh

# Verify backup was created
ls -la /opt/vault/backups/
```

### **3. Test in Development First:**

```bash
# Never test destructive commands on production/staging
# Use a separate test environment
```

### **4. Double-Check Commands:**

```bash
# Always verify what you're about to run
echo "About to run: docker compose down"
# NOT: docker compose down -v
```

## 📊 **Quick Reference**

| Command                         | Data Safe? | Use Case          |
| ------------------------------- | ---------- | ----------------- |
| `docker compose down`           | ✅ YES     | Normal stop       |
| `docker compose down -v`        | ❌ NO      | **DESTROYS DATA** |
| `docker compose restart`        | ✅ YES     | Service restart   |
| `docker compose up -d`          | ✅ YES     | Start services    |
| `docker system prune`           | ✅ YES     | Safe cleanup      |
| `docker system prune --volumes` | ❌ NO      | **DESTROYS DATA** |
| `rm -rf ./docker/`              | ❌ NO      | **DESTROYS DATA** |

## 🔍 **Data Verification Commands**

### **Check Data Integrity:**

```bash
# Verify Vault data exists
ls -la ./docker/vault/data/
cat ./docker/vault/data/root_token.txt

# Verify Consul data exists
ls -la ./docker/consul/data/
sudo ls -la ./docker/consul/data/raft/

# Test Vault accessibility
export VAULT_ADDR="http://localhost:8200"
vault status

# Test health
./health-check.sh
```

### **Backup Verification:**

```bash
# List available backups
ls -lh /opt/vault/backups/

# Check backup contents
tar -tzf /opt/vault/backups/vault_backup_*.tar.gz | head -10

# Verify backup size (should be > 1MB typically)
du -h /opt/vault/backups/vault_backup_*.tar.gz
```

## ⚠️ **Warning Signs**

**If you see these, STOP immediately:**

- Empty data directories: `ls ./docker/vault/data/` shows nothing
- Vault asking for initialization again after restart
- Missing root token file
- Consul logs showing "no peers" or "new cluster"
- All your secrets are gone when you check Vault UI

**Recovery Action:** Restore from backup immediately using the procedures above.

---

**Remember:** Your Vault secrets are stored in Consul, and Consul data is in `./docker/consul/data/`. Protect this directory at all costs!
