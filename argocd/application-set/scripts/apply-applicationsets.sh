#!/usr/bin/env bash

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTX="${CTX:-kcd-argo}"

kubectl apply -f "$BASE_DIR/../kcd-2025-appset-list.yaml" --context "$CTX"
