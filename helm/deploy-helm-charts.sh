#!/usr/bin/env bash

set -euo pipefail

echo "###########################################"
echo "# Deploying Helm charts..."
echo "###########################################"

helm upgrade --install kcd-2025-mookup . \
  -n kcd --create-namespace \
  -f kcd_west_values.yaml \
  --set fullnameOverride=kcd-2025-mookup \
  --kube-context kcd-west

helm upgrade --install kcd-2025-mookup . \
  -n kcd --create-namespace \
  -f kcd_east_values.yaml \
  --set fullnameOverride=kcd-2025-mookup \
  --kube-context kcd-east

echo "###########################################"
echo "# Check Kubernetes Resources (kcd-west)"
echo "###########################################"

kubectl get deploy,po,svc,cm -n kcd --context kcd-west

echo "###########################################"
echo "# Check Kubernetes Resources (kcd-east)"
echo "###########################################"

kubectl get deploy,po,svc,cm -n kcd --context kcd-east
