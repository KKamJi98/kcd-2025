#!/usr/bin/env bash

set -euo pipefail

aws eks update-kubeconfig --region ap-northeast-2 --name kkamji-west --alias kkamji-west
aws eks update-kubeconfig --region ap-northeast-2 --name kkamji-east --alias kkamji-east

argocd login argocd.kkamji.net --username admin

argocd cluster add kkamji-west -y
argocd cluster add kkamji-east -y