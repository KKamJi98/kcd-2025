#!/usr/bin/env bash

set -euo pipefail

delete_if_exists() {
  local full_name="$1"         # e.g., argocd/kcd-2025-west or kcd-2025-west
  local app_name="${full_name##*/}"

  if argocd app get "$app_name" >/dev/null 2>&1; then
    echo "[INFO] Deleting $full_name"
    # Best-effort delete; don't stop on transient errors
    argocd app delete "$full_name" --cascade -y || true
    # Wait for deletion operation if present; ignore errors if app disappears quickly
    argocd app wait "$app_name" --operation || true
  else
    echo "[INFO] Application $app_name not found; skipping"
  fi
}

delete_if_exists "argocd/kcd-2025-west"
delete_if_exists "argocd/kcd-2025-east"
