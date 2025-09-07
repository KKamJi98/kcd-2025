# App of Apps

Argo CD Application-of-Applications 구성을 관리하는 디렉터리입니다. 동/서부 루트 애플리케이션과 단계별(phase1~3) 애플리케이션 선언을 포함합니다.

## Finalizer

- 모든 Application 매니페스트에 `metadata.finalizers`로 `resources-finalizer.argocd.argoproj.io`를 추가했습니다.
- 목적: Application 삭제 시 하위 리소스가 먼저 정리(prune)된 뒤 Application이 제거되도록 보장합니다.

## 적용(Apply)

```bash
./apply-applications.sh
# 또는
kubectl apply -f west-root-application.yaml --context kkamji
kubectl apply -f east-root-application.yaml --context kkamji
```

## 삭제(Delete)

```bash
./delete-applications.sh
# 내부적으로 다음과 같이 실행됩니다.
argocd app delete argocd/kcd-2025-root-west --cascade -y
argocd app delete argocd/kcd-2025-root-east --cascade -y
```

## 검증(Verify)

```bash
kubectl get app kcd-2025-root-east -n argocd -o yaml | rg finalizers
kubectl get app kcd-2025-root-west -n argocd -o yaml | rg finalizers
```

## Sync Hooks

- sync-wave의 단계적 진행(0 → 1 → 2)을 보장하기 위해 Sync Hook Job을 추가했습니다.
- 위치: `east/sync-hooks.yaml`, `west/sync-hooks.yaml`
- 동작:
  - wave 1: 이전 단계 Application(phase1)이 Healthy/Synced가 될 때까지 대기
  - wave 2: 이전 단계 Application(phase2)이 Healthy/Synced가 될 때까지 대기
- Hook 어노테이션: `argocd.argoproj.io/hook: Sync`, `argocd.argoproj.io/hook-delete-policy: HookSucceeded`
- RBAC은 Job보다 먼저 생성되도록 wave 0에 배치했습니다.
