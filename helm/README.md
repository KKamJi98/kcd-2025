# kcd-2025 Demo 저장용 Nginx Helm Chart

이 저장소는 Cloud Native Korea Community Day 2025(KCD 2025) 데모용
Nginx Helm 차트. ConfigMap 기반 HTML 템플릿과 환경변수를 사용해
`[kcd-west]` 또는 `[kcd-east]` 형식의 배너 문구 렌더링

## 주요 특징

- 이미지: `nginx:stable-alpine3.21-perl`
- 출력: 중앙 정렬, 깔끔한 단일 페이지
- 자원: Deployment, Service, ConfigMap
- 보안: `readOnlyRootFilesystem: true` 유지, 필요한 경로만 쓰기 가능
- 안정화: `/etc/nginx/conf.d`를 `emptyDir`로 마운트하고 initContainer로
  `default.conf` 주입 → 엔트리포인트 수정 경고 방지

## 사전 요구 사항

- Kubernetes 1.30+
- Helm 3.16+

## 설치/업그레이드

- 릴리스 이름: `kcd-2025-mookup`

서쪽(west) 값으로 설치

```bash
helm upgrade --install kcd-2025-mookup . \
  -n kcd --create-namespace \
  -f kcd_west_values.yaml \
  --set fullnameOverride=kcd-2025-mookup
```

동쪽(east) 값으로 설치

```bash
helm upgrade --install kcd-2025-mookup . \
  -n kcd --create-namespace \
  -f kcd_east_values.yaml \
  --set fullnameOverride=kcd-2025-mookup
```

배포 후 서비스 확인

```bash
kubectl -n kcd get deploy,po,svc -l app.kubernetes.io/name=kcd-2025
```

포트포워딩(네임스페이스 표기)

```bash
kubectl -n kcd port-forward svc/kcd-2025-mookup 8080:80
```

> 참고: `fullnameOverride` 미사용 시 Service 기본 이름은
> `<release>-kcd-2025` 형식. 예: 릴리스 이름이 `declarative`라면
> `svc/declarative-kcd-2025`로 포트포워딩 가능

## 값 파일 예시

두 파일 모두 저장소 루트에 포함

- `kcd_west_values.yaml`:

```yaml
prefix: kcd
region: west
```

- `kcd_east_values.yaml`:

```yaml
prefix: kcd
region: east
```

기본 `values.yaml` 핵심 값

```yaml
prefix: kcd
region: west
```

## 설계 메모(보안/안정성)

- 루트 파일시스템 읽기 전용 유지
- 다음 경로는 `emptyDir`로 쓰기 가능하게 마운트:
  - `/etc/nginx/conf.d`(nginx confd)
  - `/var/cache/nginx`(캐시)
  - `/var/run`(런타임 소켓)
  - `/tmp`(임시 파일)
- initContainer가 ConfigMap의 `default.conf`를 confd 디렉터리에 복사
  - 엔트리포인트 IPv6 보정 스크립트 정상 동작
- HTML은 `/etc/nginx/templates`에 템플릿으로 제공, 컨테이너 시작 시
  envsubst가 `/usr/share/nginx/html`로 렌더링

## 동작 방식 요약

- 템플릿 경로: `/etc/nginx/templates`
- 출력 경로: `/usr/share/nginx/html`
- 템플릿 확장자: `.template`
- 환경변수: `PREFIX`, `REGION`(values로 주입)
- 리스닝 포트: 컨테이너 8080, Service는 80 → 8080(TargetPort) 전달
- Nginx confd 구성:
  - `nginx-confd-configmap.yaml`의 `default.conf`를 initContainer가
    `/etc/nginx/conf.d`로 복사
  - ConfigMap 볼륨은 내부적으로 심볼릭 링크 사용 → 복사 시 링크 해제 후
    실제 파일 생성 위해 `cp -rLv` 사용

## 볼륨/마운트 구성

- `/etc/nginx/templates`: ConfigMap(`*-html`) 직접 마운트(읽기 전용)
- `/usr/share/nginx/html`: `emptyDir` — envsubst 결과물 기록
- `/etc/nginx/conf.d`: `emptyDir` — initContainer가 `default.conf` 채움
- `/var/cache/nginx`, `/var/run`, `/tmp`: `emptyDir`

## 문제 해결(nginx 기동 실패)

증상 로그 예시:

```text
open() "/etc/nginx/conf.d/default.conf" failed (2: No such file or directory)
```

점검 순서

1) initContainer conf 복사 수행 여부 확인

```bash
kubectl -n kcd logs <pod> -c init-confd
```

2) confd 경로 파일 존재 여부 확인(기동 중인 경우)

```bash
kubectl -n kcd exec -it <pod> -c nginx -- ls -al /etc/nginx/conf.d
```

3) 차트 템플릿 확인 포인트

- `Deployment` init 스크립트가 `cp -rLv /confd-src/* /confd/` 인지 확인
- `/etc/nginx/conf.d`가 `emptyDir`로 마운트되어 있는지 확인
- `nginx-confd-configmap.yaml`에 `default.conf` 존재 여부 확인

4) ConfigMap 변경 자동 반영(선택)

- Pod 템플릿 체크섬 주입으로 conf 변경 시 자동 롤아웃 유도 가능

예시(주석)

```yaml
metadata:
  annotations:
    checksum/confd: {{ include (print $.Template.BasePath "/nginx-confd-configmap.yaml") . | sha256sum }}
```

## 제거

```bash
helm uninstall kcd-2025-declarative -n kcd
```

## 참고

- 자세한 작업 흐름과 운영 메모는 `helm/AGENTS.md`와 리포지토리 루트 `AGENTS.md` 참고
