#!/usr/bin/env bash

set -euo pipefail

kubectl apply -f east-application.yaml --context kcd-argo
kubectl apply -f west-application.yaml --context kcd-argo
