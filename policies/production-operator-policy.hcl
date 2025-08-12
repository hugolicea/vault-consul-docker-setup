# Production Operator Policy - Production secrets + limited admin
path "production/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "production/metadata/*" {
  capabilities = ["list", "delete"]
}

# Read access to staging for migrations
path "staging/data/*" {
  capabilities = ["read", "list"]
}

# Limited system access
path "sys/health" {
  capabilities = ["read"]
}

path "sys/mounts" {
  capabilities = ["read"]
}

path "sys/auth" {
  capabilities = ["read"]
}

# User management in their scope
path "auth/userpass/users/prod-*" {
  capabilities = ["create", "read", "update", "delete"]
}
