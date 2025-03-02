provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }
  required_version = ">= 1.3.0"
}