terraform {
  required_version = ">= 1.1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.2.2"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }

  }
}

provider "aws" {
  region  = var.region
  profile = var.profile
}
