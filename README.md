# kcd-2025

Cloud Native Korea Community Day 2025 발표 데모 저장소입니다.

- 목적: 발표 데모 코드, 매니페스트, IaC와 자료를 관리합니다.
- 범위: Kubernetes, GitOps, Observability 등 클라우드 네이티브 주제.
- 상태: 준비 중(초기 구성 진행).

## Quick Start

- Requirements: Docker, a Kubernetes cluster, `kubectl` ≥ 1.28, `helm` ≥ 3.12.
- Run: Demo-specific guides will be added under `docs/`.

## Repository Overview

- `argocd/`: GitOps configurations and application definitions.
- `helm/`: Helm charts and values files.
- `terraform/`: Infrastructure as Code examples.
- `README.md`: Project introduction and guide.

## 서비스 포트포워딩

### west 클러스터 CoreDNS 서비스 포트포워딩 (8080 -> 80, Local -> Service)

```bash
kubectl --context kkamji-west -n kcd port-forward svc/mookup-kcd-2025 8080:80
```

### east 클러스터 CoreDNS 서비스 포트포워딩 (8081 -> 80, Local -> Service)

```bash
kubectl --context kkamji-east -n kcd port-forward svc/mookup-kcd-2025 8081:80
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

