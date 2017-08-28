# Instructions for Deploying and Using the Sock Shop Demo
The Sock Shop Microservices Demo consists of 13 microservices which provide the customer-facing part of an e-commerce application. These services are written in several languages, including node.js, Java, and Go, and use RabbitMQ, 1 MySQL and 3 MongoDB databases. The demo is deployable on many platforms including Docker, Kubernetes, Amazon ECS, Mesos, Apcera, and Nomad.

You can learn more about the demo at the [Sock Shop](https://microservices-demo.github.io/) website which also includes links to all the source code and Docker images used by the demo.

The instructions below describe how you can deploy the Sock Shop microservices to AWS using [Nomad](https://www.nomadproject.io/), [Consul](https://www.consul.io), and [Vault](https://www.vaultproject.io). Additionally, [Packer](https://www.packer.io) is used to build the AWS AMI, [Terraform](https://www.terraform.io) is used to provision the AWS infrastructure, a local Vault server is used to dynamically provision AWS credentials to Terraform, and a [Vagrant](https://www.vagrantup.com) VM is launched on your laptop to run the local software.

## Prerequisites
In order to deploy the Sock Shop demo to AWS, you will need an AWS account. You will also need to know your AWS access and secret access [keys](http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys). You'll also need a [key pair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) from your AWS account. Of course, you'll also want to clone or download this repository to your laptop. In a terminal session, you would use `git clone https://github.com/rberlind/hashicorp-demo.git`.

## Launching Packer, Terraform, and Vault locally
A [Vagrantfile](./aws/Vagrantfile) is included so that you can install and launch Packer, Terraform, and Vault in a single VM, making the usage of the demo more predictable for all users.

To launch the Vagrant VM, open a Terminal shell, navigate to the aws directory and run `vagrant up`. Don't worry about a lot of ugly-looking text including some that is red that scrolls by; that is mostly just software being downloaded with curl.

Once the Vagrant VM is created, run `vagrant ssh` to connect to it. Note that your prompt should change to something like "vagrant@vagrant-ubuntu-trusty-64:~$".

You now want to initialize the Vault server that is included in the VM as follows:

1. `cd vault`
1. Run the Vault server with `vault server -config=vault.hcl > vault.log &`
1. `export VAULT_ADDR=http://127.0.0.1:8200`
1. `vault init -key-shares=1 -key-threshold=1`
1. Be sure to notice the Unseal Key 1 and Initial Root Token which you will need.  These will not be shown to you again.
1. Unseal Vault with `vault unseal`.  Provide the Unseal Key 1 when prompted. You should get feedback saying that Vault is unsealed.
1. Export your Vault root token with `export VAULT_TOKEN=<root_token>`, replacing \<root_token\> with the initial root token returned when you initialized Vault.

Your Vault server is now unsealded and ready to use, but we also want to add in the Vault AWS secret backend and set it up to dynamically provision AWS credentials for each Terraform run.

1. Mount the Vault AWS Backend with `vault mount aws`.
1. Write your AWS keys to Vault, replacing \<your_key\> and \<your_secret_key\> with your actual AWS keys:

`vault write aws/config/root \
 access_key=<your_key> \
 secret_key=<your_secret_key>`

You should see "Success! Data written to: aws/config/root"

1. Add a policy to Vault with `vault write aws/roles/deploy policy=@policy.json`. You should see "Success! Data written to: aws/roles/deploy".
1. Test that you can dynamically generate AWS credentials by running `vault read aws/creds/deploy`.  This will return an access key and secret key usable for 32 days. If you want the credentials to only be valid for 30 minutes, run `curl --header "X-Vault-Token:<your_root_token>" --request POST --data '{"lease": "30m", "lease_max": "24h"}' http://localhost:8200/v1/aws/config/lease`, being sure to replace \<your_root_token\> with your initial Vault root token. You can repleat the previous command to verify that your generated AWS credentials are now only valid for 30 minutes.






## Setting up your local Vault server

## Provisioning ec2 instances with Terraform

## Setting up the Vault server in AWS

## Launching the Sock Shop application with Nomad

## Using the Sock Shop application

## Checking the Sock Shop services with Consul UI and Weave Scope
