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
