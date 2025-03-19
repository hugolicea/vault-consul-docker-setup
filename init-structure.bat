@echo off

mkdir docker\vault\config
mkdir docker\vault\tls
mkdir docker\vault\policies
mkdir docker\consul\config
mkdir docker\consul\data

type nul > docker\vault\config\vault.hcl
type nul > docker\vault\init-unseal.sh
type nul > docker\consul\config\consul.hcl
type nul > docker-compose.yml

echo [OK] Directory structure for Vault + Consul project created successfully.
pause
