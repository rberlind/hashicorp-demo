## Instructions for Initializing Vault on Nomad Server

1. `vault init -key-shares=1 -key-threshold=1`
1. `vault unseal`
1. `export VAULT_TOKEN=<ROOT_TOKEN>`
1. `./setup_vault.sh`
