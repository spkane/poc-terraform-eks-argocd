module "cluster" {
  source = "../../__modules/eks"

  profile            = var.profile
  region             = var.region
  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.vpc.outputs.public_subnet_ids
  tags               = var.tags
}
