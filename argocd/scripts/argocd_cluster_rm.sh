#!/usr/bin/env bash

set -euo pipefail

argocd login argocd.kkamji.net --username admin --grpc-web

argocd cluster rm kcd-west -y
argocd cluster rm kcd-east -y
