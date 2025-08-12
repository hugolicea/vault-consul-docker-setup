#!/bin/sh

# Simple approach - just run vault server and let manual init handle the rest
vault server -config=/vault/config/vault.hcl
