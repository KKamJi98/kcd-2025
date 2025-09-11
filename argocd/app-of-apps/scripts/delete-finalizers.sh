#!/usr/bin/env bash

set -euo pipefail

NAMESPACE=argocd

for app in $(kubectl --context kcd-argo get applications.argoproj.io -n $NAMESPACE \
  -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep kcd-2025); do
  echo "Removing finalizers from $app"
  kubectl --context kcd-argo patch application $app -n $NAMESPACE --type=json \
    -p='[{"op":"remove","path":"/metadata/finalizers"}]'
done
