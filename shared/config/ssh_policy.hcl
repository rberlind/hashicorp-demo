# This section grants write access on ssh/creds/otp_key_role
path "ssh/creds/otp_key_role" {
  capabilities = ["create", "update" ]
}

# This section gives read access on the rest of the ssh path
path "ssh/*" {
  capabilities = ["read"]
}
