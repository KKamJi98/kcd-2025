#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-argocd}"
CTX="${CTX:-kcd-argo}"

for app in $(kubectl --context "$CTX" get applications.argoproj.io -n "$NAMESPACE" \
  -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep kcd-2025); do
  echo "Removing finalizers from $app"
  kubectl --context "$CTX" patch application "$app" -n "$NAMESPACE" --type=json \
    -p='[{"op":"remove","path":"/metadata/finalizers"}]'
done
