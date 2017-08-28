# Instructions for Deploying and Using the Sock Shop Demo
The Sock Shop Microservices Demo consists of 13 microservices which provide the customer-facing part of an e-commerce application. These services are written in several languages, including node.js, Java, and Go, and use RabbitMQ, 1 MySQL and 3 MongoDB databases. The demo is deployable on many platforms including Docker, Kubernetes, Amazon ECS, Mesos, Apcera, and Nomad.

You can learn more about the demo at the [Sock Shop](https://microservices-demo.github.io/) website which also includes links to all the source code and Docker images used by the demo.

The instructions below describe how you can deploy the Sock Shop microservices to AWS using [Nomad](https://www.nomadproject.io/), [Consul](https://www.consul.io), and [Vault](https://www.vaultproject.io). Additionally, [Packer](https://www.packer.io) is used to build the AWS AMI, [Terraform](https://www.terraform.io) is used to provision the AWS infrastructure, a local Vault server is used to dynamically provision AWS credentials to Terraform, and a [Vagrant](https://www.vagrantup.com) VM is launched on your laptop to run the local software.

All the Sock Shop microservices will be launched in Docker containers, using Nomad's Docker Driver.

## Prerequisites
In order to deploy the Sock Shop demo to AWS, you will need an AWS account. You will also need to know your AWS access and secret access [keys](http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys). You'll also need a [key pair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) from your AWS account. Of course, you'll also want to clone or download this repository to your laptop. In a terminal session, you would use `git clone https://github.com/rberlind/hashicorp-demo.git`.

## Launching Packer, Terraform, and Vault locally
A [Vagrantfile](./aws/Vagrantfile) is included so that you can install and launch Packer, Terraform, and Vault in a single VM, making the usage of the demo more predictable for all users.

To launch the Vagrant VM, open a Terminal shell, navigate to the aws directory and run `vagrant up`. Don't worry about a lot of ugly-looking text including some that is red that scrolls by; that is mostly just software being downloaded with curl.

Once the Vagrant VM is created, run `vagrant ssh` to connect to it. Note that your prompt should change to something like "vagrant@vagrant-ubuntu-trusty-64:~$".

## Setting up your local Vault server
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

```
vault write aws/config/root \
 access_key=<your_key> \
 secret_key=<your_secret_key>
```

You should see "Success! Data written to: aws/config/root"

1. Add a policy to Vault with `vault write aws/roles/deploy policy=@policy.json`. You should see "Success! Data written to: aws/roles/deploy".
1. Test that you can dynamically generate AWS credentials by running `vault read aws/creds/deploy`.  This will return an access key and secret key usable for 32 days. If you want the credentials to only be valid for 30 minutes, run `curl --header "X-Vault-Token:<your_root_token>" --request POST --data '{"lease": "30m", "lease_max": "24h"}' http://localhost:8200/v1/aws/config/lease`, being sure to replace \<your_root_token\> with your initial Vault root token. You can repeat the previous command to verify that your generated AWS credentials are now only valid for 30 minutes.

## Provisioning AWS ec2 instances with Packer and Terraform
You can now use Packer and Terraform to provision your AWS ec2 instances. Terraform has already been configured to retrieve AWS credentials from your local Vault server.

I've already used Packer to create a public Amazon Machine Image (AMI), ami-ed7f7296, which you can use as the basis for your ec2 instances. This AMI only exists in the AWS us-east-1 region. If you want to create a similar AMI in a different region or if you make any changes to any of the files in the aws or shared directories, you will need to create your own AMI with Packer. This is very simple. Starting from the /home/vagrant directory inside your Vagrant VM, do the following (being sure to specify the region in packer.json if different from us-east-1):

```
cd aws/packer
packer build packer.json
cd ..
```
Be sure to note the AMI ID of your new AMI and to enter this as the value of the ami variable in the terraform.tfvars file under the aws/env/us-east directory. Save that file.

Before using Terraform, you need to use one of your AWS EC2 key pairs or [create](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair) a new one. Please download your private key and copy it to the aws directory to make connecting to your ec2 instances easier.  Be sure to specify the name of your key in the value for the "key_name" variable in terraform.tfvars under the aws/env/us-east directory and save that file before continuing.

Now, you're ready to use Terraform to provision your ec2 instances.  The current configuration creates 1 Server VM running Nomad, Consul, and Vault servers and 2 Client VMs running Nomad and Consul.  Your Sock Shop apps will be deployed by Nomad to the Client VMs.

1. `cd env/us-east` where you will find the Terraform files.
1. Run `terraform plan` to validate your Terraform configuration. You should see a message at the end saying that Terraform found 7 objects to add, 0 to chnage, and 0 to destroy.
1. Run `terraform apply` to provision your infrastructure. When this finishes, you should see a message giving the public and private IP addresses for all 3 instances.  Write these down for later reference. In your AWS console, you should be able to see all 3 instances under EC2 Instances. If you were already on that screen, you'll need to refresh it.

## Connecting to your ec2 instances
If you copied your private EC2 key pair to the aws directory of your Vagrant VM, you can connect to your Nomad server with `ssh -i <key> ubuntu@<server_public_ip>`, replacing \<key\> with your actual private key file (ending in ".pem") and \<server_public_ip\> with the public IP of your server instance.

After connecting, if you run the `pwd` command, you will see that you are in the /home/ubuntu directory. If you run the `ls` command, you should see 3 files: setup_vault.sh, sockshop.nomad, and ssh_policy.hcl.

## Setting up the Vault server in AWS
You now need to set up the Vault server on your ec2 Server instance so that Nomad can retrieve a dynamically generated password when running the catalogue-db task which creates and runs a MySQL database. This password will be passed into the Docker container running the catalogue-db database and will be assigned to the MYSQL_ROOT_PASSWORD environment variable which sets the MySQL password for the root user of the database.

## Launching the Sock Shop application with Nomad

## Using the Sock Shop application

## Checking the Sock Shop services with Consul UI and Weave Scope
