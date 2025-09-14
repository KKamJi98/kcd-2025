#!/usr/bin/env bash

set -euo pipefail

#
# apply-destroy-all.sh
# 1) destroy: kcd-argo 컨텍스트에서 Argo CD Application/ApplicationSet 모두 삭제 후 완전 삭제 대기, 이후 병렬 destroy
# 2) apply: 세 클러스터(kcd-argo, kcd-east, kcd-west) terraform apply (병렬 실행)
# 3) 모든 apply/destroy 실행 결과를 각 클러스터 디렉토리의 last-results.log에 기록
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ACTION="${1:-}"
ARGO_CTX="${ARGO_CTX:-kcd-argo}"
ARGO_NS="${ARGO_NS:-argocd}"
CLUSTERS=("kcd-argo" "kcd-east" "kcd-west")
TF_COMMON_FLAGS=("-input=false" "-no-color")
TF_LOCK_TIMEOUT="5m"
WAIT_TIMEOUT_SECONDS=${WAIT_TIMEOUT_SECONDS:-300}
WAIT_INTERVAL_SECONDS=${WAIT_INTERVAL_SECONDS:-5}

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

usage() {
  cat <<USAGE
Usage: bash $SCRIPT_NAME <apply|destroy>

Description:
  - apply   : terraform apply for kcd-argo, kcd-east, kcd-west (parallel)
  - destroy : delete Argo CD Applications/ApplicationSets, then terraform destroy (parallel)

Environment variables:
  ARGO_CTX                Argo CD kube context (default: kcd-argo)
  ARGO_NS                 Argo CD namespace (default: argocd)
  WAIT_TIMEOUT_SECONDS    Wait timeout for Argo deletions (default: 300)
  WAIT_INTERVAL_SECONDS   Poll interval for Argo deletions (default: 5)
USAGE
}

if [[ -z "$ACTION" ]]; then
  usage
  exit 1
fi

case "$ACTION" in
  apply|destroy) ;;
  -h|--help) usage; exit 0 ;;
  *) echo "[ERROR] ACTION must be 'apply' or 'destroy'" >&2; usage; exit 1 ;;
esac

echo "[STEP 0] Ensure kubeconfigs exist"
if [[ -x "$SCRIPT_DIR/update-kubeconfig.sh" ]]; then
  "$SCRIPT_DIR/update-kubeconfig.sh" || true
else
  echo "[WARN] update-kubeconfig.sh not found; assuming contexts exist"
fi

if [[ "$ACTION" == "destroy" ]]; then
  echo "[STEP 1] Deleting Argo CD Applications and ApplicationSets in context '$ARGO_CTX' namespace '$ARGO_NS'"
fi

ns_exists() {
  kubectl get ns "$ARGO_NS" --context "$ARGO_CTX" >/dev/null 2>&1
}

crd_supported() {
  local res="$1" # e.g., applications.argoproj.io
  kubectl api-resources --context "$ARGO_CTX" -o name 2>/dev/null | grep -qx "$res"
}

delete_argo_resources() {
  if ! ns_exists; then
    echo "[INFO] Namespace '$ARGO_NS' not found in context '$ARGO_CTX'; skip deletion"
    return 0
  fi

  local deleted_any=false

  if crd_supported "applications.argoproj.io"; then
    echo "[INFO] kubectl delete applications.argoproj.io --all -n $ARGO_NS"
    kubectl delete applications.argoproj.io --all -n "$ARGO_NS" --ignore-not-found --context "$ARGO_CTX" || true
    deleted_any=true
  else
    echo "[INFO] CRD applications.argoproj.io not present; skipping"
  fi

  if crd_supported "applicationsets.argoproj.io"; then
    echo "[INFO] kubectl delete applicationsets.argoproj.io --all -n $ARGO_NS"
    kubectl delete applicationsets.argoproj.io --all -n "$ARGO_NS" --ignore-not-found --context "$ARGO_CTX" || true
    deleted_any=true
  else
    echo "[INFO] CRD applicationsets.argoproj.io not present; skipping"
  fi

  if [[ "$deleted_any" == false ]]; then
    echo "[INFO] Nothing to delete (no CRDs/namespace); proceeding"
  fi
}

remaining_count() {
  local res="$1" # applications.argoproj.io or applicationsets.argoproj.io
  # If CRD or namespace is missing, treat as zero
  if ! ns_exists || ! crd_supported "$res"; then
    echo 0
    return 0
  fi
  local cnt
  # If get fails (e.g., transient), treat as zero to avoid flapping
  if ! cnt=$(kubectl get "$res" -n "$ARGO_NS" --context "$ARGO_CTX" -o name 2>/dev/null | wc -l | tr -d ' '); then
    echo 0
  else
    echo "$cnt"
  fi
}

wait_for_deletion() {
  local deadline=$(( $(date +%s) + WAIT_TIMEOUT_SECONDS ))
  while true; do
    local apps_left appssets_left
    apps_left=$(remaining_count "applications.argoproj.io")
    appssets_left=$(remaining_count "applicationsets.argoproj.io")
    echo "[WAIT] remaining: applications=$apps_left, applicationsets=$appssets_left"
    if [[ "$apps_left" -eq 0 && "$appssets_left" -eq 0 ]]; then
      echo "[OK] All Argo CD Applications/ApplicationSets deleted"
      break
    fi
    if (( $(date +%s) > deadline )); then
      echo "[ERROR] Timeout waiting for Argo CD resources to delete" >&2
      return 1
    fi
    sleep "$WAIT_INTERVAL_SECONDS"
  done
}

if [[ "$ACTION" == "destroy" ]]; then
  delete_argo_resources
  wait_for_deletion
fi

echo "[STEP 2] Terraform $ACTION"

export TF_IN_AUTOMATION=1

run_tf() {
  local cluster="$1"
  local dir="$SCRIPT_DIR/clusters/$cluster"
  if [[ ! -d "$dir" ]]; then
    echo "[ERROR] Cluster dir not found: $dir" >&2
    return 2
  fi

  local log_file="$dir/last-results.log"
  : > "$log_file"  # truncate

  echo "==== [$cluster] terraform init ($(date -Iseconds)) ====\n" | tee -a "$log_file"
  if ! terraform -chdir="$dir" init "${TF_COMMON_FLAGS[@]}" 2>&1 | tee -a "$log_file"; then
    echo "[ERROR] terraform init failed for $cluster" | tee -a "$log_file"
    return 3
  fi

  if [[ "$ACTION" == "apply" ]]; then
    echo "\n==== [$cluster] terraform apply -auto-approve ($(date -Iseconds)) ====\n" | tee -a "$log_file"
    terraform -chdir="$dir" apply -auto-approve -lock-timeout="$TF_LOCK_TIMEOUT" "${TF_COMMON_FLAGS[@]}" 2>&1 | tee -a "$log_file"
  else
    echo "\n==== [$cluster] terraform destroy -auto-approve ($(date -Iseconds)) ====\n" | tee -a "$log_file"
    terraform -chdir="$dir" destroy -auto-approve -lock-timeout="$TF_LOCK_TIMEOUT" "${TF_COMMON_FLAGS[@]}" 2>&1 | tee -a "$log_file"
  fi

  echo "\n==== [$cluster] terraform $ACTION done ($(date -Iseconds)) ====\n" | tee -a "$log_file"
}

FAIL=0

echo "[INFO] Running terraform $ACTION in parallel: ${CLUSTERS[*]}"
PIDS=()
NAMES=()
for c in "${CLUSTERS[@]}"; do
  run_tf "$c" &
  PIDS+=("$!")
  NAMES+=("$c")
done

for i in "${!PIDS[@]}"; do
  pid="${PIDS[$i]}"; name="${NAMES[$i]}"
  if ! wait "$pid"; then
    echo "[ERROR] $ACTION failed for $name" >&2
    FAIL=1
  else
    echo "[OK] $ACTION succeeded for $name"
  fi
done

if [[ "$FAIL" -ne 0 ]]; then
  echo "[DONE] Some $ACTION operations failed" >&2
  exit 1
fi

echo "[DONE] All $ACTION operations completed successfully"
