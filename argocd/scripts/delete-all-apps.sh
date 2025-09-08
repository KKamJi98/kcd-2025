#!/usr/bin/env bash

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[INFO] Deleting ApplicationSet apps (if any)"
if [[ -x "$BASE_DIR/application-set/delete-applicationsets.sh" ]]; then
  "$BASE_DIR/application-set/delete-applicationsets.sh" || true
else
  echo "[WARN] application-set/delete-applicationsets.sh not found; skipping"
fi

echo "[INFO] Deleting App-of-Apps root applications"
if [[ -x "$BASE_DIR/app-of-apps/delete-applications.sh" ]]; then
  "$BASE_DIR/app-of-apps/delete-applications.sh" || true
else
  echo "[WARN] app-of-apps/delete-applications.sh not found; skipping"
fi

echo "[INFO] Deleting Declarative applications"
if [[ -x "$BASE_DIR/declarative_application/delete-applications.sh" ]]; then
  "$BASE_DIR/declarative_application/delete-applications.sh" || true
else
  echo "[WARN] declarative_application/delete-applications.sh not found; skipping"
fi

echo "[INFO] Removing finalizers for stuck Applications (best-effort)"
if [[ -x "$BASE_DIR/app-of-apps/delete-finalizers.sh" ]]; then
  "$BASE_DIR/app-of-apps/delete-finalizers.sh" || true
else
  echo "[WARN] app-of-apps/delete-finalizers.sh not found; skipping finalizer cleanup"
fi

echo "[DONE] All delete routines executed"

