#!/usr/bin/env bash

set -euo pipefail

aws eks update-kubeconfig --region ap-northeast-2 --name kcd-west --alias kcd-west
aws eks update-kubeconfig --region ap-northeast-2 --name kcd-east --alias kcd-east

argocd login argocd.kkamji.net --username admin --grpc-web

argocd cluster add kcd-west -y
argocd cluster add kcd-east -y
