#!/usr/bin/env bash

set -euo pipefail

delete_if_exists() {
  local full_name="$1"           # e.g., argocd/kcd-2025-root-west
  local app_name="${full_name##*/}"

  if argocd app get "$app_name" >/dev/null 2>&1; then
    echo "[INFO] Deleting $full_name"
    argocd app delete "$full_name" --cascade -y || true
    argocd app wait "$app_name" --operation || true
  else
    echo "[INFO] Application $app_name not found; skipping"
  fi
}

delete_if_exists "argocd/kcd-2025-root-west"
delete_if_exists "argocd/kcd-2025-root-east"
