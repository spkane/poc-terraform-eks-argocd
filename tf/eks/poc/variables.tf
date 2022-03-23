variable "profile" {
  type = string
  description = "AWS profile"
}

variable "region" {
  type = string
  description = "AWS region"
}

variable "cluster_name" {
  type = string
  description = "EKS cluster name"
}

variable "cluster_version" {
  type = string
  description = "K8S version"
}

variable "tags" {
  type = map(string)
  description = "AWS region"
}
