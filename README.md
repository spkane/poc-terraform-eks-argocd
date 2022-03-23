# Terraform - Provision an EKS Cluster w/ ArgoCD

- **Forked** from: [hashicorp/learn-terraform-provision-eks-cluster](https://github.com/hashicorp/learn-terraform-provision-eks-cluster) and updated to use the most recent providers and moduiles.
  - The original repo is a companion repo to the [Provision an EKS Cluster learn guide](https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster), containing Terraform configuration files to provision an EKS cluster on AWS.

---

**Note**: This a proof of concept and is not intended to be an example of best practices. It you are going to implement something like this in into your platform there are multiple things that you should consider:

- [Using ArgoCD Application Sets](https://argocd-applicationset.readthedocs.io/en/stable/)
- Determine if you want to rely on branches or Kustomize overlays for code promotion between environments.
- Automation
- Security configuration
- Storage configuration
