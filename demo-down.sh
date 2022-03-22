#!/usr/bin/env bash

set -euo pipefail

# Force the AWS profile to use
export AWS_PROFILE="so-personal"

cd tf

# Get the EKS cluster name and set the Kubernetes context
export DEMO_CLUSTER_NAME=$(terraform output -raw cluster_name)
aws eks update-kubeconfig --name "$DEMO_CLUSTER_NAME"

# Login to ArgoCD
argocd login $(kubectl get svc argocd-server -n argocd --no-headers -o=custom-columns=LB:.status.loadBalancer.ingress[0].hostname) --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo) --insecure

# Delete emissary-ingress
argocd app delete -y emissary-ingress
kubectl delete -f https://app.getambassador.io/yaml/emissary/2.2.2/emissary-crds.yaml

# Revert ArgoCD, so that it is no longer using an AWS Load Balancer
# This prevents Terraform from getting stuck when it tears down the cluster.
argocd app sync argocd

# Unset the Kubernetes context
kubectl config unset current-context

# Tear down the EKS cluster and related resources
terraform destroy -auto-approve
cd ..

exit 0

