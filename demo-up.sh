#!/usr/bin/env bash

set -euo pipefail

# Force the AWS profile to use
export AWS_PROFILE="so-personal"

cd tf
# Spin up the EKS cluster and related resources
terraform apply -auto-approve

# Get the EKS cluster name and set the Kubernetes context
export DEMO_CLUSTER_NAME=$(terraform output -raw cluster_name)
aws eks update-kubeconfig --name "$DEMO_CLUSTER_NAME"

# Helm install Argo CD
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm || true
helm repo update
helm install -n argocd argocd argo/argo-cd
kubectl patch cm argocd-cm -n argocd -p '{"data": {"resource.compareoptions": "ignoreAggregatedRoles: true\n"}}'

# Expose Argo CD via an AWS Load Balancer and then configure the argocd CLI
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
sleep 120
argocd login $(kubectl get svc argocd-server -n argocd --no-headers -o=custom-columns=LB:.status.loadBalancer.ingress[0].hostname) --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo) --insecure

# Setup Argo CD to manage itself
argocd cluster add -y --in-cluster --name local "arn:aws:eks:us-west-2:865894413136:cluster/$DEMO_CLUSTER_NAME"
argocd app create argocd --repo https://argoproj.github.io/argo-helm --helm-chart argo-cd --revision 4.2.0 --dest-namespace argocd --dest-server https://kubernetes.default.svc --sync-policy none
argocd app sync argocd --async
kubectl patch cm argocd-cm -n argocd -p '{"data": {"resource.compareoptions": "ignoreAggregatedRoles: true\n"}}'

# Since we are not using our own repo for Argo CD in this demo, we lost some of our configs with the manual sync
# Let's re-apply then and then relogin via the argocd CLI
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
sleep 120
argocd login $(kubectl get svc argocd-server -n argocd --no-headers -o=custom-columns=LB:.status.loadBalancer.ingress[0].hostname) --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo) --insecure

# Let's install emissary-ingress
# CRDs will be via kubectl for now
# The rest of the app will be via Argo CD & helm
kubectl apply -f https://app.getambassador.io/yaml/emissary/2.2.2/emissary-crds.yaml
argocd app create emissary-ingress --repo https://app.getambassador.io --helm-chart emissary-ingress --revision 7.3.2 --dest-namespace emissary --dest-server https://kubernetes.default.svc --sync-policy automated --sync-option CreateNamespace=true

# Let's open up the Argo CD web UI
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
open https://$(kubectl get svc argocd-server -n argocd --no-headers -o=custom-columns=LB:.status.loadBalancer.ingress[0].hostname)
cd ..

# Setup git repos and add an emissary upgrade step for a future demo

exit 0
