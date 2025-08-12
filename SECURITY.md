# Security Setup Guide

## Why Do This?

**Problem:** You're currently using the "root token" for everything. This is like using the "Administrator" account for daily work - it's dangerous and not recommended.

**Solution:** Create admin users that can do almost everything but are much safer for daily operations.

## Quick Setup (5 minutes)

### Step 1: Run the Admin Setup Script

```bash
# On your staging server (app03-staging)
cd /opt/vault/docker-vault-consul

# Set environment
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN=$(cat ./docker/vault/data/root_token.txt)

# Run the setup (this creates admin users)
./setup-admin-users.sh
```

**What this script does:**

- ✅ Creates an "admin" policy (almost like root, but safer)
- ✅ Enables username/password login
- ✅ Creates your admin user account
- ✅ Tests that it works
- ✅ Saves your admin token

### Step 2: Test Your New Admin User

```bash
# Login with your new admin user (instead of root token)
vault login -method=userpass username=your-admin-username

# Test that you can still do everything
vault secrets list
vault kv put secret/mytest key=value
vault kv get secret/mytest
```

### Step 3: Use Admin User Daily

**From now on, use your admin user instead of root token:**

```bash
# Login method 1: With username/password
vault login -method=userpass username=your-admin-username

# Login method 2: With saved admin token
export VAULT_TOKEN=$(cat ./docker/vault/data/admin_token.txt)
```

## What's Different?

| Root Token | Admin User |
|------------|------------|
| ❌ Can break everything | ✅ Safe daily operations |
| ❌ Can't be revoked easily | ✅ Can be disabled anytime |
| ❌ If compromised = disaster | ✅ If compromised = manageable |
| ❌ No audit trail | ✅ Clear audit trail |

## Advanced: Root Token Management

**After you're comfortable with admin users:**

### Option 1: Keep Root Token Safe

```bash
# Save root token in password manager
echo "Root Token: $(cat ./docker/vault/data/root_token.txt)"

# Then remove from server (optional)
rm ./docker/vault/data/root_token.txt
```

### Option 2: Revoke Root Token (Advanced)

```bash
# ⚠️ ONLY if you're confident admin access works perfectly
# Test admin access first!
vault login -method=userpass username=your-admin-username
vault secrets list  # Should work

# If admin works perfectly, revoke root token
vault token revoke $(cat ./docker/vault/data/root_token.txt)
```

## Emergency Recovery

**If you need root access again:**

```bash
# Stop services and reset (nuclear option)
docker compose down
sudo rm -rf ./docker/consul/data/*
docker compose up -d
# This creates a fresh setup with new root token
```

## Troubleshooting

**"Command not found" errors:**

- Make sure you're on the Linux server (SSH to app03-staging)
- Make sure you're in the right directory (`/opt/vault/docker-vault-consul`)

**"Permission denied" errors:**

- Make sure Vault is running: `docker compose ps`
- Make sure you set VAULT_ADDR: `export VAULT_ADDR="http://localhost:8200"`

**Admin user login fails:**

- Use root token to check: `vault read auth/userpass/users/your-username`
- Reset admin user: Re-run `./setup-admin-users.sh`
