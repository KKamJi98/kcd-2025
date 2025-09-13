#!/usr/bin/env bash

set -euo pipefail

argocd login kcd-argo.kkamji.net --username admin --grpc-web

argocd cluster rm kcd-west -y
argocd cluster rm kcd-east -y
