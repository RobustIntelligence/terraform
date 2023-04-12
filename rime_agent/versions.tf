terraform {
  required_version = "> 0.14, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0, < 4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1, < 3.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}
