#!/usr/bin/env bash

set -euo pipefail

# Force the AWS profile to use
export AWS_PROFILE="so-personal"

cd tf
# Get the EKS cluster name and set the Kubernetes context
terraform workspace select staging
export STAGING_CLUSTER_NAME=$(terraform output -raw cluster_name)
aws eks update-kubeconfig --name "$STAGING_CLUSTER_NAME"

# Delete Apps directly (although we could use ArgoCD to do this)
kubectl delete -k k8s/emissary-ingress/overlays/staging
kubectl delete -k k8s/emissary-ingress-shared/overlays/staging

terraform workspace select poc
export POC_CLUSTER_NAME=$(terraform output -raw cluster_name)
aws eks update-kubeconfig --name "$POC_CLUSTER_NAME"
cd ..

# Delete Apps directly (although we could use ArgoCD to do this)
kubectl delete -k k8s/emissary-ingress/overlays/poc
kubectl delete -k k8s/emissary-ingress-shared/overlays/poc
kubectl delete -k k8s/argo-workflows/overlays/poc
kubectl delete -k k8s/argocd/overlays/poc

# Unset the Kubernetes context
kubectl config unset current-context

cd tf
# Tear down the EKS cluster and related resources
terraform workspace select staging
terraform destroy -auto-approve
terraform workspace delete staging
terraform workspace select poc
terraform destroy -auto-approve
terraform workspace delete poc
cd ..

exit 0

