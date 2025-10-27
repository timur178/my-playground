terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Team        = var.team
      Environment = var.environment
      Project     = var.project
    }
  }
}
