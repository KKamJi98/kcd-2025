#!/usr/bin/env bash

set -euo pipefail

argocd login argocd.kkamji.net --username admin --grpc-web

argocd cluster rm kkamji-west -y
argocd cluster rm kkamji-east -y
