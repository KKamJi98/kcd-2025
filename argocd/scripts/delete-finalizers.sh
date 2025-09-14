#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-argocd}"
CTX="${CTX:-kcd-argo}"

# Try to list applications; if CRD or namespace is missing, skip gracefully
apps=$(kubectl --context "$CTX" get applications.argoproj.io -n "$NAMESPACE" \
  -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)

if [[ -z "${apps:-}" ]]; then
  echo "[INFO] No Applications found or CRD missing; skipping finalizer removal"
  exit 0
fi

for app in $apps; do
  [[ $app != kcd-2025* ]] && continue
  echo "Removing finalizers from $app"
  # Best-effort: ignore races where the app disappears mid-operation
  kubectl --context "$CTX" patch application "$app" -n "$NAMESPACE" --type=json \
    -p='[{"op":"remove","path":"/metadata/finalizers"}]' || true
done
