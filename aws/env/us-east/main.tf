variable "region" {
  description = "The AWS region to deploy to."
  default     = "us-east-1"
}

variable "ami" {}

variable "server_instance_type" {
  description = "The AWS instance type to use for servers."
  default     = "t2.medium"
}

variable "client_instance_type" {
  description = "The AWS instance type to use for clients."
  default     = "t2.large"
}

variable "key_name" {}

variable "server_count" {
  description = "The number of servers to provision."
  default     = "3"
}

variable "client_count" {
  description = "The number of clients to provision."
  default     = "4"
}

variable "cluster_tag_value" {
  description = "Used by Consul to automatically form a cluster."
  default     = "auto-join"
}

provider "vault" {}

data "vault_generic_secret" "aws_auth" {
  path = "aws/creds/deploy"
}

data "external" "region" {
  # workaround for Vault bug
  # https://github.com/terraform-providers/terraform-provider-aws/issues/1086
  program = ["./delay-vault-aws"]
}

provider "aws" {
  region = "${data.external.region.result["region"]}"
  access_key = "${data.vault_generic_secret.aws_auth.data["access_key"]}"
  secret_key = "${data.vault_generic_secret.aws_auth.data["secret_key"]}"
}

module "hashistack" {
  source = "../../modules/hashistack"

  region            = "${var.region}"
  ami               = "${var.ami}"
  server_instance_type     = "${var.server_instance_type}"
  client_instance_type     = "${var.client_instance_type}"
  key_name          = "${var.key_name}"
  server_count      = "${var.server_count}"
  client_count      = "${var.client_count}"
  cluster_tag_value = "${var.cluster_tag_value}"
}

output "IP_Addresses" {
  value = <<CONFIGURATION

Client public IPs: ${join(", ", module.hashistack.client_public_ips)}
Client private IPs: ${join(", ", module.hashistack.client_private_ips)}
Server public IPs: ${join(", ", module.hashistack.primary_server_public_ips)}
Server private IPs: ${join(", ", module.hashistack.primary_server_private_ips)}

To connect, add your private key and SSH into any client or server with
`ssh ubuntu@PUBLIC_IP`. You can test the integrity of the cluster by running:

  $ consul members
  $ nomad server-members
  $ nomad node-status

If you see an error message like the following when running any of the above
commands, it usuallly indicates that the configuration script has not finished
executing:

"Error querying servers: Get http://127.0.0.1:4646/v1/agent/members: dial tcp
127.0.0.1:4646: getsockopt: connection refused"

Simply wait a few seconds and rerun the command if this occurs.

The Consul UI can be accessed at http://PUBLIC_IP:8500/ui.

CONFIGURATION
}
