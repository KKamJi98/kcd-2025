#!/usr/bin/env bash

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The manifest file lives one level above the scripts directory
kubectl apply -f "$BASE_DIR/../kcd-2025-appset-list.yaml" --context kcd-argo
