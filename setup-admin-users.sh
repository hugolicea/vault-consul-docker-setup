#!/bin/bash

# Vault Admin User Setup Script
# Run this ONCE after initial Vault setup

set -e

echo "🔐 Setting up Vault admin users and security policies..."

# Check if we're authenticated
if ! vault token lookup > /dev/null 2>&1; then
    echo "❌ Please authenticate with root token first:"
    echo "   export VAULT_ADDR=\"http://localhost:8200\""
    echo "   export VAULT_TOKEN=\$(cat ./docker/vault/data/root_token.txt)"
    echo "   vault login -method=token"
    exit 1
fi

echo "✅ Authenticated with Vault"

# 1. Create admin policy
echo "📋 Creating admin policy..."
vault policy write admin-policy - <<EOF
# Admin policy - nearly full access but not root
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Deny access to root token generation
path "sys/generate-root/*" {
  capabilities = ["deny"]
}

# Deny access to unseal keys
path "sys/unseal" {
  capabilities = ["deny"]
}

# Allow policy management
path "sys/policies/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Allow auth method management
path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Allow secret engine management
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF

# 2. Enable userpass auth method
echo "👤 Enabling userpass authentication..."
vault auth enable userpass 2>/dev/null || echo "   (userpass already enabled)"

# 3. Create admin user
echo "🔑 Creating admin user..."
read -p "Enter admin username: " ADMIN_USER
read -s -p "Enter admin password: " ADMIN_PASS
echo

vault write auth/userpass/users/$ADMIN_USER \
    password=$ADMIN_PASS \
    policies=admin-policy

echo "✅ Admin user '$ADMIN_USER' created with admin-policy"

# 4. Test admin user login
echo "🧪 Testing admin user login..."
ADMIN_TOKEN=$(vault write -field=token auth/userpass/login/$ADMIN_USER password=$ADMIN_PASS)

if [ -n "$ADMIN_TOKEN" ]; then
    echo "✅ Admin user login successful!"
    echo "   Admin token: $ADMIN_TOKEN"

    # Save admin token for convenience
    echo $ADMIN_TOKEN > ./docker/vault/data/admin_token.txt
    chmod 600 ./docker/vault/data/admin_token.txt
    echo "   Token saved to: ./docker/vault/data/admin_token.txt"
else
    echo "❌ Admin user login failed!"
    exit 1
fi

# 5. Show next steps
echo ""
echo "🎉 Setup complete! Next steps:"
echo ""
echo "1. Test admin access:"
echo "   export VAULT_TOKEN=$ADMIN_TOKEN"
echo "   vault auth -method=token"
echo "   vault secrets list"
echo ""
echo "2. To login as admin user:"
echo "   vault auth -method=userpass -path=userpass username=$ADMIN_USER"
echo ""
echo "3. To revoke root token (OPTIONAL - only if you're sure):"
echo "   vault token revoke \$(cat ./docker/vault/data/root_token.txt)"
echo ""
echo "4. Store credentials securely:"
echo "   - Admin username: $ADMIN_USER"
echo "   - Admin password: [save in password manager]"
echo "   - Root token: [save in password manager, then delete file]"
echo ""
echo "⚠️  IMPORTANT: Test admin access thoroughly before revoking root token!"
