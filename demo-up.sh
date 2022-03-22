#!/usr/bin/env bash

set -euo pipefail

# Force the AWS profile to use
export AWS_PROFILE="so-personal"

cd tf
# Spin up the EKS cluster and related resources
terraform apply -auto-approve

# Get the EKS cluster name and set the Kubernetes context
export DEMO_CLUSTER_NAME=$(terraform output -raw cluster_name)
export DEMO_ACCOUNT_NUMBER=$(aws sts get-caller-identity --query "Account" --output text)
aws eks update-kubeconfig --name "$DEMO_CLUSTER_NAME"
cd ..

# Install Argo CD
cd k8s/argocd
kubectl apply -k overlays/poc
sleep 120
argocd login $(kubectl get svc argocd-server -n argocd --no-headers -o=custom-columns=LB:.status.loadBalancer.ingress[0].hostname) --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo) --insecure

# Setup Argo CD to manage itself
argocd cluster add -y --in-cluster --name local "arn:aws:eks:us-west-2:$DEMO_ACCOUNT_NUMBER:cluster/$DEMO_CLUSTER_NAME"
argocd repo add https://github.com/spkane/poc-terraform-eks-argocd --name poc
argocd app create argocd --repo https://github.com/spkane/poc-terraform-eks-argocd --path k8s/argocd/overlays/poc --dest-namespace argocd --dest-server https://kubernetes.default.svc
argocd app sync argocd --async
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

# Let's open up the Argo CD web UI
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
open https://$(kubectl get svc argocd-server -n argocd --no-headers -o=custom-columns=LB:.status.loadBalancer.ingress[0].hostname)

# Setup git repos and add an emissary upgrade step for a future demo

exit 0
