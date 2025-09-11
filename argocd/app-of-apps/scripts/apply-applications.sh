#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTX="${CTX:-kcd-argo}"

kubectl apply -f "$SCRIPT_DIR/../west-root-application.yaml" --context "$CTX"
kubectl apply -f "$SCRIPT_DIR/../east-root-application.yaml" --context "$CTX"
