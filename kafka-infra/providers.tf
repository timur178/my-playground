terraform {
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 6.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.29.0" }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Team        = var.team
      Environment = var.environment
    }
  }
}

# data "aws_eks_cluster" "this" { name = var.eks_cluster_name }
# data "aws_eks_cluster_auth" "this" { name = var.eks_cluster_name }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.this.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.this.token
# }
