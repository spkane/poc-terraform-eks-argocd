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

  }
}

provider "aws" {
  region  = var.region
  profile = var.profile

  // This is necessary with the VPC module we are using here
  // so that tags required for eks can be applied to the vpc
  // without changes to the vpc wiping them out.
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging
  ignore_tags {
    key_prefixes = ["kubernetes.io/"]
  }
}
