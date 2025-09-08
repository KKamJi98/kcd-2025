# kcd-2025

Cloud Native Korea Community Day 2025 발표 데모 저장소입니다.

- 목적: 발표 데모 코드, 매니페스트, IaC와 자료를 관리합니다.
- 범위: Kubernetes, GitOps, Observability 등 클라우드 네이티브 주제.
- 상태: 준비 중(초기 구성 진행).

## Quick Start

- Requirements: Docker, a Kubernetes cluster, `kubectl` ≥ 1.28, `helm` ≥ 3.12.
- Guides: 배포별 가이드는 `helm/README.md`, `argocd/app-of-apps/README.md`, `argocd/application-set/README.md`를 참고하세요.

## Repository Overview

- `argocd/`: GitOps configurations and application definitions.
- `helm/`: Helm charts and values files.
- `terraform/`: Infrastructure as Code examples.
- `README.md`: Project introduction and guide.

## 서비스 포트포워딩

배포 방식에 따라 Helm 릴리스명과 Service 이름이 다릅니다.

- Declarative(Applications): 릴리스 `declarative` → Service `declarative-kcd-2025`
- App of Apps(phase1~3): 릴리스 `app-of-apps-phase<N>` → Service `app-of-apps-phase<N>-kcd-2025`
- ApplicationSet: 릴리스 `appset` → Service `appset-kcd-2025`

### west 클러스터 데모 서비스 포트포워딩 (8080 -> 80)

```bash
kubectl --context kcd-west -n kcd port-forward svc/declarative-kcd-2025 8080:80
```

### east 클러스터 데모 서비스 포트포워딩 (8081 -> 80)

```bash
kubectl --context kcd-east -n kcd port-forward svc/declarative-kcd-2025 8081:80
```

### ApplicationSet 배포 포트포워딩 예시

```bash
# west
kubectl --context kcd-west -n kcd port-forward svc/appset-kcd-2025 8080:80

# east
kubectl --context kcd-east -n kcd port-forward svc/appset-kcd-2025 8080:80
```

### App of Apps(phase별) 포트포워딩 예시

```bash
# phase1 (west)
kubectl --context kcd-west -n kcd port-forward svc/app-of-apps-phase1-kcd-2025 8080:80

# phase2 (east)
kubectl --context kcd-east -n kcd port-forward svc/app-of-apps-phase2-kcd-2025 8080:80
```

## Talk Information

- Event: Cloud Native Korea Community Day 2025
- Speaker: Taeji Kim (KKamJi)
- Slides/Video: Links will be shared after the talk.

## Commit Convention

- Commit Message: `<type>: <summary>` (`feat|fix|docs|chore|refactor|test|style|perf|ci`).
- Example: `docs: add project README`.

## Contact

- GitHub: https://github.com/KKamJi98
- Email: rlaxowl5460@gmail.com
