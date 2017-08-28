#!/bin/bash

# Script to complete setup of Vault and start Nomad

echo "Before running this, you must first do the following:"
echo "   vault init -key-shares=1 -key-threshold=1"
echo "which will give you and Unseal Key 1 and Initial Root Token"
echo "   vault unseal"
echo "to which you must provide the Unseal Key 1"
echo "   export VAULT_TOKEN=<Initial_Root_Token>"


# Setup Vault policy/role after manually initializing & unsealing it
echo "Setting up Vault policy and role"
curl https://nomadproject.io/data/vault/nomad-server-policy.hcl -O -s -L
vault policy-write nomad-server nomad-server-policy.hcl
curl https://nomadproject.io/data/vault/nomad-cluster-role.json -O -s -L
vault write /auth/token/roles/nomad-cluster @nomad-cluster-role.json

# Get token for Vault
TOKEN_FOR_VAULT=`vault token-create -policy nomad-server -period 72h -orphan | sed -e '1,2d' | sed -e '2,6d' | sed 's/ //g' | cut -f2`
sudo sed -i "s/TOKEN_FOR_VAULT/$TOKEN_FOR_VAULT/g" /etc/nomad.d/nomad.hcl
echo "The generated Vault token is: $TOKEN_FOR_VAULT"

# Setup the Vault SSH secret backend
echo "Setting up the Vault SSH secret backend"
vault mount ssh
vault write ssh/roles/otp_key_role key_type=otp default_user=root cidr_list=172.17.0.0/24

# Test that we can generate a password
echo "Testing that we can generate a password"
vault write ssh/creds/otp_key_role ip=172.17.0.1

# Write ssh_policy into Vault
vault write sys/policy/ssh_policy rules=@ssh_policy.hcl

# Start Nomad which should now be able to start with Vault enabled
sudo service nomad start
