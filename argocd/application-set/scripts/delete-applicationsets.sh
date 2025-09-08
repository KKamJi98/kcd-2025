#!/usr/bin/env bash

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE=argocd

# Delete the ApplicationSet resource(s)
kubectl delete -f "$BASE_DIR/kcd-2025-appset-list.yaml" --ignore-not-found --context kkamji

# Ensure generated Applications are also cleaned up
for region in east west; do
  app="kcd-2025-appset-${region}"
  kubectl delete application "$app" -n "$NAMESPACE" --ignore-not-found --context kkamji
done
