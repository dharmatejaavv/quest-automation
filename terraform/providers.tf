terraform {
  required_version = ">= 1.3"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.48"
    }
  }

  backend "s3" {
    key                  = "quest.tfstate"
    #profile              = "dev"
    workspace_key_prefix = "quest-Automation"
    region               = "us-east-2"
    bucket               = "quest.backend.terraform.state"
    encrypt              = true
  }
}

provider "docker" {
  # Configuration for Docker provider (if needed)
}

provider "aws" {
  region = "eu-west-1"
  #profile = "dev"
  default_tags {
    tags = {
      Creation   = "IaC"
      Maintainer = "Dharma teja"
    }
  }
}

# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = module.eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
#     }
#   }
# }
