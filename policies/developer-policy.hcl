# Developer Policy - Read/Write access to staging secrets only
path "staging/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "staging/metadata/*" {
  capabilities = ["list"]
}

# Read-only access to production for debugging
path "production/data/*" {
  capabilities = ["read", "list"]
}

# No admin or system access
path "sys/*" {
  capabilities = ["deny"]
}

path "auth/*" {
  capabilities = ["deny"]
}
