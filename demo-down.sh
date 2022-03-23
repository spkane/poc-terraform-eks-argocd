#!/usr/bin/env bash

set -euo pipefail

# Force the AWS profile to use
export AWS_PROFILE="so-personal"

# Get the Staging EKS cluster name and set the Kuberetes context
cd tf/eks/staging
export STAGING_CLUSTER_NAME=$(terraform output -raw cluster_name)
aws eks update-kubeconfig --name "$STAGING_CLUSTER_NAME"
cd ../../..

# Delete Apps directly (although we could use ArgoCD to do this)
kubectl delete -k k8s/emissary-ingress/overlays/staging
kubectl delete -k k8s/emissary-ingress-shared/overlays/staging

# Get the PoC EKS cluster name and set the Kuberetes context
cd tf/eks/poc
export POC_CLUSTER_NAME=$(terraform output -raw cluster_name)
aws eks update-kubeconfig --name "$POC_CLUSTER_NAME"
cd ../../..

# Delete Apps directly (although we could use ArgoCD to do this)
kubectl delete -k k8s/emissary-ingress/overlays/poc
kubectl delete -k k8s/emissary-ingress-shared/overlays/poc
kubectl delete -k k8s/argo-workflows/overlays/poc
kubectl delete -k k8s/argocd/overlays/poc

# Unset the Kubernetes context
kubectl config unset current-context

cd tf/eks/staging
# Tear down the Staging EKS cluster and related resources
terraform destroy -auto-approve
cd ../../..

cd tf/eks/poc
# Tear down the PoC EKS cluster and related resources
terraform destroy -auto-approve
cd ../../..

cd tf/network
# Tear down the PoC EKS cluster and related resources
terraform destroy -auto-approve
cd ../..

exit 0
