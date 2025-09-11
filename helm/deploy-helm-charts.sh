#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEST_CTX="${WEST_CTX:-kcd-west}"
EAST_CTX="${EAST_CTX:-kcd-east}"

echo "###########################################"
echo "# Deploying Helm charts..."
echo "###########################################"

helm upgrade --install kcd-2025-mookup "$SCRIPT_DIR" \
  -n kcd --create-namespace \
  -f "$SCRIPT_DIR/kcd_west_values.yaml" \
  --set fullnameOverride=kcd-2025-mookup \
  --kube-context "$WEST_CTX"

helm upgrade --install kcd-2025-mookup "$SCRIPT_DIR" \
  -n kcd --create-namespace \
  -f "$SCRIPT_DIR/kcd_east_values.yaml" \
  --set fullnameOverride=kcd-2025-mookup \
  --kube-context "$EAST_CTX"

echo "###########################################"
echo "# Check Kubernetes Resources (kcd-west)"
echo "###########################################"

kubectl get deploy,po,svc,cm -n kcd --context "$WEST_CTX"

echo "###########################################"
echo "# Check Kubernetes Resources (kcd-east)"
echo "###########################################"

kubectl get deploy,po,svc,cm -n kcd --context "$EAST_CTX"
