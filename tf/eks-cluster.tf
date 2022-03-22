locals {
  cluster_name = "eks-poc-${random_string.suffix.result}"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.10.1"
  cluster_name    = local.cluster_name
  cluster_tags    = {
    architecture  = "thor"
    domain        = "platform"
    env           = "poc"
    owner         = "the-a-team"
    owner-contact = "mr-t@example.com"
    product-line  = "shared"
    team          = "a"
  }
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

  cluster_version = "1.20"
  subnet_ids      = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

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
    }
    {
      name                            = "istio-v1"
      launch_template_name            = "istio-v1"
      launch_template_use_name_prefix = true
      instance_type                   = "t2.small"
      additional_security_group_ids   = [aws_security_group.all_worker_mgmt.id]
      asg_desired_capacity            = 1
    },
    {
      name                            = "observability-v1"
      launch_template_name            = "observability-v1"
      launch_template_use_name_prefix = true
      instance_type                   = "t2.small"
      additional_security_group_ids   = [aws_security_group.all_worker_mgmt.id]
      asg_desired_capacity            = 1
    }
  ]
}
