variable "profile" {
  type = string
  description = "AWS profile"
  default     = "so-personal"
}

variable "region" {
  type = string
  description = "AWS region"
  default     = "us-west-2"
}

variable "cluster_name" {
  type = string
  description = "EKS cluster name"
}

variable "cluster_version" {
  type = string
  description = "K8S version"
  default = "1.20"
}

variable "private_subnet_ids" {
    type = list(string)
  description = "List of private subnet ids"
}

variable "public_subnet_ids" {
    type = list(string)
  description = "List of public subnet ids"
}

variable "vpc_id" {
  type = string
  description = "VPC ID"
}

variable "tags" {
  type = map(string)
  description = "AWS region"
  default     = {
    architecture  = "unset"
    domain        = "unset"
    env           = "unset"
    owner         = "unset"
    owner-contact = "unset"
    product-line  = "unset"
    team          = "unset"
  }
}
