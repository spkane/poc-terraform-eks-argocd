resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  cluster_name = "${var.cluster_name}-${random_string.suffix.result}"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.10.1"
  cluster_name    = local.cluster_name
  cluster_tags    = var.tags
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  cluster_version = var.cluster_version
  subnet_ids      = var.private_subnet_ids

  vpc_id = var.vpc_id

  eks_managed_node_group_defaults = {
    root_volume_type = "gp2"
  }

  eks_managed_node_groups = [
    {
      name                            = "ondemand-v1"
      launch_template_name            = "ondemand-v1"
      launch_template_use_name_prefix = true
      instance_type                   = "t2.small"
      additional_security_group_ids   = [aws_security_group.all_worker_mgmt.id]
      asg_desired_capacity            = 1
    },
    {
      name                            = "other-v1"
      launch_template_name            = "other-v1"
      launch_template_use_name_prefix = true
      instance_type                   = "t2.small"
      additional_security_group_ids   = [aws_security_group.all_worker_mgmt.id]
      asg_desired_capacity            = 1
    }
  ]
}

// Add tags to the VPC and subnets that is required for load balancer support
resource "aws_ec2_tag" "vpc_tag" {
  resource_id = var.vpc_id
  key         = "kubernetes.io/cluster/${local.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "private_subnet_tag" {
  for_each    = toset(var.private_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_subnet_cluster_tag" {
  for_each    = toset(var.private_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "public_subnet_tag" {
  for_each    = toset(var.public_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_cluster_tag" {
  for_each    = toset(var.public_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.cluster_name}"
  value       = "shared"
}
