![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Version](https://img.shields.io/github/v/release/hugolicea/vault-consul-docker-setup)
![License](https://img.shields.io/badge/license-MIT-blue)

# Vault + Consul Docker Setup

This repository provides a Docker-based setup for running HashiCorp Vault and Consul. It includes automated initialization and unsealing processes for Vault, making it easy to get started with local development and testing.

## Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Create the Directory Structure](#2-create-the-directory-structure)
  - [3. Start the Services](#3-start-the-services)
  - [4. Initialize and Unseal Vault](#4-initialize-and-unseal-vault)
  - [5. Access Vault](#5-access-vault)
  - [6. Verify Vault Status](#6-verify-vault-status)
- [Configuration](#configuration)
  - [1. Vault Configuration](#1-vault-configuration)
  - [2. Consul Configuration](#2-consul-configuration)
  - [3. TLS Support](#3-tls-support)
  - [4. Cleaning Up](#4-cleaning-up)
- [License](#license)

## Features

- **Vault**: Secure secrets management and data encryption.
- **Consul**: Backend storage for Vault with service discovery.
- **Automated Initialization**: Automatically initializes Vault if not already initialized.
- **Automated Unsealing**: Automatically unseals Vault using stored unseal keys.
- **TLS Support**: Includes configuration for running Vault with TLS (optional).

## Prerequisites

- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

## Getting Started

1. Clone the Repository

```sh
git clone https://github.com/hugolicea/vault-consul-docker-setup.git
cd vault-consul-docker-setup
```

2. Create the Directory Structure
   Run the init-structure.bat script to create the necessary directories and files:
   [init-structure.bat](http://_vscodecontentref_/9)

3. Start the Services
   Use Docker Compose to start Vault and Consul:
   docker-compose up -d

4. Initialize and Unseal Vault
   Run the init-unseal.sh script to initialize and unseal Vault:
   docker exec -it vault [init-unseal.sh](http://_vscodecontentref_/10)

5. Access Vault
   Vault UI: http://localhost:8200
   Consul UI: http://localhost:8500

6. Verify Vault Status
   Check the status of Vault:
   docker exec -it vault vault status

## Configuration

1. Vault Configuration
   The Vault configuration is located in docker/vault/config/vault.hcl. It uses Consul as the storage backend and runs without TLS by default.

2. Consul Configuration
   The Consul configuration is located in docker/consul/config/consul.hcl. It runs as a single-node server with the UI enabled.

3. TLS Support
   To enable TLS for Vault, update the vault.hcl file and mount the tls/ directory in the docker-compose.yml file.

4. Cleaning Up
   To stop and remove the containers:

   ```sh
   docker-compose down
   ```

   To clear all data (including unseal keys and tokens):

   ```sh
   rm -rf docker/consul/data/*
   rm -rf docker/vault/data/*
   ```

### License
This project is licensed under the MIT License. See the LICENSE file for details.
