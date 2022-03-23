output "region" {
  description = "AWS region"
  value       = var.region
}

output "private_subnet_ids" {
  description = "List of private subnet ids"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "List of public subnet ids"
  value       = module.vpc.public_subnets
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
