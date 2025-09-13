#!/usr/bin/env bash
set -euo pipefail

ACTION=""
UPGRADE="false"
AUTO_APPROVE="false"
CLUSTERS=("kcd-east" "kcd-west" "kcd-argo")

usage() {
  cat <<'USAGE'
Usage: bash clusters/run-all.sh <plan|apply> [--upgrade] [--yes] [--clusters kcd-east,kcd-west,kcd-argo]

Options:
  --upgrade            Run 'terraform init -upgrade' before action
  --yes                For apply, use '-auto-approve'
  --clusters <list>    Comma-separated cluster dirs (default: kcd-east,kcd-west,kcd-argo)

Examples:
  bash clusters/run-all.sh plan
  bash clusters/run-all.sh apply --yes
  bash clusters/run-all.sh plan --clusters kcd-east,kcd-argo
  bash clusters/run-all.sh apply --yes --upgrade --clusters kcd-west
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

ACTION="$1"; shift
case "$ACTION" in
  plan|apply) ;;
  *) echo "[ERROR] ACTION must be 'plan' or 'apply'"; usage; exit 1 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --upgrade)
      UPGRADE="true"; shift ;;
    --yes)
      AUTO_APPROVE="true"; shift ;;
    --clusters)
      shift
      IFS=',' read -r -a CLUSTERS <<< "${1:-}"
      if [[ -z "${CLUSTERS:-}" ]]; then echo "[ERROR] --clusters needs a value"; exit 1; fi
      shift ;;
    -h|--help)
      usage; exit 0 ;;
    *) echo "[WARN] Unknown arg: $1"; shift ;;
  esac
done

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CLUSTERS_DIR="$ROOT_DIR/clusters"

run_in_cluster() {
  local dir="$1"
  echo "\n==> [$dir] running terraform $ACTION"
  cd "$CLUSTERS_DIR/$dir"

  if [[ "$UPGRADE" == "true" ]]; then
    terraform init -upgrade -input=false
  else
    terraform init -input=false
  fi

  case "$ACTION" in
    plan)
      terraform plan -input=false ;;
    apply)
      if [[ "$AUTO_APPROVE" == "true" ]]; then
        terraform apply -auto-approve -input=false
      else
        terraform apply -input=false
      fi ;;
  esac
}

for c in "${CLUSTERS[@]}"; do
  if [[ ! -d "$CLUSTERS_DIR/$c" ]]; then
    echo "[ERROR] Cluster dir not found: $c" >&2
    exit 1
  fi
done

for c in "${CLUSTERS[@]}"; do
  run_in_cluster "$c"
done

echo "\nAll done."

