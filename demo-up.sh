#!/usr/bin/env bash

set -euo pipefail

# Force the AWS profile to use
export AWS_PROFILE="so-personal"

cd tf
terraform init
terraform workspace new poc
terraform workspace new staging

# Spin up the PoC EKS cluster
terraform workspace select poc
terraform apply -auto-approve
export POC_CLUSTER_NAME=$(terraform output -raw cluster_name)
export POC_ACCOUNT_NUMBER=$(aws sts get-caller-identity --query "Account" --output text)
aws eks update-kubeconfig --name "$POC_CLUSTER_NAME"

# Spin up the Staging EKS cluster
terraform workspace select staging
terraform apply -auto-approve
export STAGING_CLUSTER_NAME=$(terraform output -raw cluster_name)
export STAGING_ACCOUNT_NUMBER=$(aws sts get-caller-identity --query "Account" --output text)
aws eks update-kubeconfig --name "$STAGING_CLUSTER_NAME"
cd ..

# Set the current Kubernetes context to the PoC cluster
aws eks update-kubeconfig --name "$POC_CLUSTER_NAME"

# Install Argo CD to the PoC cluster
cd k8s/argocd
kubectl apply -k overlays/poc
sleep 120
argocd login $(kubectl get svc argocd-server -n argocd --no-headers -o=custom-columns=LB:.status.loadBalancer.ingress[0].hostname) --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo) --insecure

# Setup Argo CD to manage itself
argocd cluster add -y --in-cluster --name local "arn:aws:eks:us-west-2:$POC_ACCOUNT_NUMBER:cluster/$POC_CLUSTER_NAME"
argocd repo add https://github.com/spkane/poc-terraform-eks-argocd --name poc
argocd app create argocd --repo https://github.com/spkane/poc-terraform-eks-argocd --path k8s/argocd/overlays/poc --dest-namespace argocd --dest-server https://kubernetes.default.svc
argocd app sync argocd --async
cd ../..

# Let's install Argo Workflows
cd k8s/argo-workflows
argocd app create arg0workflows --repo https://github.com/spkane/poc-terraform-eks-argocd --path k8s/argo-workflows/overlays/poc --dest-server https://kubernetes.default.svc
argocd app sync argo-workflows --async
cd ../..

# Let's install the shared emissary-ingress CRDs
cd k8s/emissary-ingress-shared
argocd app create emissary-ingress-shared --repo https://github.com/spkane/poc-terraform-eks-argocd --path k8s/emissary-ingress-shared/overlays/poc --dest-server https://kubernetes.default.svc
argocd app sync emissary-ingress-shared --async
cd ../..

# Let's install emissary-ingress
cd k8s/emissary-ingress
argocd app create emissary-ingress --repo https://github.com/spkane/poc-terraform-eks-argocd --path k8s/emissary-ingress/overlays/poc --dest-namespace emissary --dest-server https://kubernetes.default.svc
argocd app sync emissary-ingress --async
cd ../..

## Staging Cluster Setup

# Add the staging cluster to ArgoCD in the PoC cluster
argocd cluster add -y --in-cluster --name staging "arn:aws:eks:us-west-2:$STAGING_ACCOUNT_NUMBER:cluster/$STAGING_CLUSTER_NAME"

# Let's install the shared emissary-ingress CRDs
cd k8s/emissary-ingress-shared
argocd app create emissary-ingress-shared --repo https://github.com/spkane/poc-terraform-eks-argocd --path k8s/emissary-ingress-shared/overlays/staging --dest-name staging
argocd app sync emissary-ingress-shared --async
cd ../..

# Let's install emissary-ingress
cd k8s/emissary-ingress
argocd app create emissary-ingress --repo https://github.com/spkane/poc-terraform-eks-argocd --path k8s/emissary-ingress/overlays/staging --dest-namespace emissary --dest-name staging
argocd app sync emissary-ingress --async
cd ../..

# Let's open up the Argo CD web UI
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
open https://$(kubectl get svc argocd-server -n argocd --no-headers -o=custom-columns=LB:.status.loadBalancer.ingress[0].hostname)

# Setup git repos and add an emissary upgrade step for a future demo

exit 0
