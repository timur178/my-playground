#!/bin/sh

terraform init
terraform apply -auto-approve -var-file=bootstrap.tfvars
