#!/usr/bin/env bash

set -euo pipefail

argocd login kcd-argo.kkamji.net --username admin --grpc-web || true

remove_cluster() {
  local name="$1"
  echo "[INFO] Removing cluster: $name (if registered)"
  # Best-effort removal; ignore if it does not exist
  argocd cluster rm "$name" -y || echo "[INFO] Cluster $name not found; skipping"
}

remove_cluster kcd-west
remove_cluster kcd-east
