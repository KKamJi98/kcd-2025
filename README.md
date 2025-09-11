# kcd-2025

Cloud Native Korea Community Day 2025 발표 데모 저장소

- 목적: 발표 데모 코드, 매니페스트, IaC와 자료 관리
- 범위: Kubernetes, GitOps, Observability 등 클라우드 네이티브 주제 다룸
- 상태: 준비 완료

## Quick Start

- Requirements: Docker, a Kubernetes cluster, `kubectl` ≥ 1.28, `helm` ≥ 3.12.
- Guides: 배포별 가이드는 `helm/README.md`, `argocd/app-of-apps/README.md`, `argocd/application-set/README.md` 참고

## Repository Overview

- `argocd/`: GitOps configurations and application definitions.
- `helm/`: Helm charts and values files.
- `terraform/`: Infrastructure as Code examples.
- `docs/`: 발표 슬라이드(PDF)와 문서 자료.
- `README.md`: Project introduction and guide.

## 스크립트 사용법

모든 스크립트 실행 경로 무관 동작. 필요 시 컨텍스트/네임스페이스 환경 변수로 오버라이드

### 공통 환경 변수

- `CTX`: 기본 `kcd-argo` (kubectl 대상 컨텍스트)
- `NAMESPACE`: 기본 `argocd` (Argo CD 네임스페이스)
- `WEST_CTX`: 기본 `kcd-west` (Helm/kubectl west 컨텍스트)
- `EAST_CTX`: 기본 `kcd-east` (Helm/kubectl east 컨텍스트)

### Argo CD - Declarative Applications

```bash
# east / west 애플리케이션 적용
./argocd/declarative_application/scripts/apply-applications.sh

# 삭제 스크립트(별도)
./argocd/declarative_application/scripts/delete-applications.sh
```

### Argo CD - ApplicationSet

```bash
# 적용 (어디서 실행해도 동작)
./argocd/application-set/scripts/apply-applicationsets.sh

# 컨텍스트 오버라이드 예시
CTX=my-argo ./argocd/application-set/scripts/apply-applicationsets.sh

# 삭제
./argocd/application-set/scripts/delete-applicationsets.sh

# 네임스페이스/컨텍스트 지정 삭제
NAMESPACE=argocd CTX=my-argo \
  ./argocd/application-set/scripts/delete-applicationsets.sh
```

### Argo CD - App of Apps

```bash
# 루트 애플리케이션 적용
./argocd/app-of-apps/scripts/apply-applications.sh

# 파이널라이저 정리(막힌 Application 강제 해제) 수행
./argocd/app-of-apps/scripts/delete-finalizers.sh

# 환경 변수로 컨텍스트 지정
CTX=my-argo ./argocd/app-of-apps/scripts/apply-applications.sh
```

### Argo CD - 일괄 삭제 유틸리티

```bash
# ApplicationSet, App-of-Apps, Declarative 순서로 안전하게 삭제
./argocd/scripts/delete-all-apps.sh
```

### Helm 배포

```bash
# west/east 두 컨텍스트로 차트 배포 및 리소스 확인
./helm/deploy-helm-charts.sh

# 컨텍스트 오버라이드 예시
WEST_CTX=my-west EAST_CTX=my-east ./helm/deploy-helm-charts.sh
```

## 서비스 포트포워딩

배포 방식에 따라 Helm 릴리스명과 Service 이름이 다름

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
- Slides (PDF): [다운로드](docs/ArgoCD와_함께하는_Multi_Cluster_운영.pdf)
- Video: 발표 이후 공유 예정

## Commit Convention

- Commit Message: `<type>: <summary>` (`feat|fix|docs|chore|refactor|test|style|perf|ci`).
- Example: `docs: add project README`.

## Contact

- GitHub: https://github.com/KKamJi98
- Email: rlaxowl5460@gmail.com
