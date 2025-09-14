#!/bin/bash

set -euo pipefail

# Region은 환경변수 AWS_REGION이 있으면 사용, 없으면 기본값 사용
REGION="${AWS_REGION:-ap-northeast-2}"

update_if_exists() {
  local name="$1"
  local alias="$2"
  if aws eks describe-cluster --region "$REGION" --name "$name" >/dev/null 2>&1; then
    aws eks update-kubeconfig --region "$REGION" --name "$name" --alias "$alias"
  else
    echo "[INFO] EKS cluster '$name' not found in region '$REGION'; skipping kubeconfig update" >&2
  fi
}

update_if_exists kcd-west kcd-west
update_if_exists kcd-east kcd-east
update_if_exists kcd-argo kcd-argo

# aws eks update-kubeconfig --region ap-northeast-2 --name kcd-west --alias kcd-west
# aws eks update-kubeconfig --region ap-northeast-2 --name kcd-east --alias kcd-east
# aws eks update-kubeconfig --region ap-northeast-2 --name kcd-argo --alias kcd-argo