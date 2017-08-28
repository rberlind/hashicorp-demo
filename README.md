# Instructions for Deploying and Using the Sock Shop Demo
The Sock Shop Microservices Demo consists of 13 microservices which provide the customer-facing part of an e-commerce application. These services are written in several languages, including node.js, Java, and Go, and use RabbitMQ, 1 MySQL and 3 MongoDB databases. The demo is deployable on many platforms including Docker, Kubernetes, Amazon ECS, Mesos, Apcera, and Nomad.

You can learn more about the demo at the [Sock Shop](https://microservices-demo.github.io/) website which also includes links to all the source code and Docker images used by the demo.

The instructions below describe how you can deploy the Sock Shop microservices to AWS using [Nomad](https://www.nomadproject.io/), [Consul](https://www.consul.io), and [Vault](https://www.vaultproject.io). Additionally, [Packer](https://www.packer.io) is used to build the AWS AMI, [Terraform](https://www.terraform.io) is used to provision the AWS infrastructure, a local Vault server is used to dynamically provision AWS credentials to Terraform, and a [Vagrant](https://www.vagrantup.com) VM is launched on your laptop to run the local software.

## Prerequisites
In order to deploy the Sock Shop demo to AWS, you will need an AWS account. You will also need to know your AWS access and secret access keys. Of course, you'll also want to clone or download this repository to your laptop. In a terminal session, you would use `git clone https://github.com/rberlind/hashicorp-demo.git`.

## Launching Packer, Terraform, and Vault locally
A [Vagrantfile](./aws/Vagrantfile) is included so that you can install and launch Packer, Terraform, and Vault in a single VM, making the usage of the demo more predictable for all users.

To launch the Vagrant VM, open a Terminal shell, navigate to the aws directory

## Setting up your local Vault server

## Provisioning ec2 instances with Terraform

## Setting up the Vault server in AWS

## Launching the Sock Shop application with Nomad

## Using the Sock Shop application

## Checking the Sock Shop services with Consul UI and Weave Scope
