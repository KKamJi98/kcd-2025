# Argo CD ApplicationSet

이 디렉터리는 Argo CD ApplicationSet으로 동/서부 지역(east/west)에 따라 Helm 차트를 반복 배포하기 위한 선언과 스크립트를 포함

## 개요

- 리소스: `ApplicationSet` 1개가 2개의 `Application`(east, west) 생성
- 동기화: 자동 동기화(`automated`) + `prune` + `selfHeal` 활성화로 GitOps 일관성 유지
- 템플릿: Go 템플릿(`goTemplate`) 사용, `region` 변수 바인딩

## 구성 파일

- `kcd-2025-appset-list.yaml`: ApplicationSet 선언(생성 대상 목록, 템플릿, 동기화 정책)
- `scripts/apply-applicationsets.sh`: ApplicationSet 생성/적용 스크립트
- `scripts/delete-applicationsets.sh`: ApplicationSet 및 생성된 Application 정리 스크립트

## 전제 조건

- Argo CD 설치 및 `argocd` 네임스페이스에서 동작 중
- Argo CD `AppProject` 이름 `kcd-2025` 존재, 해당 repo/path/대상 클러스터 권한 설정
- kubeconfig에 컨텍스트 `kkamji`, 대상 클러스터 `kcd-east`, `kcd-west` 구성
- Kubernetes 1.28+ 및 Argo CD 2.8+ 권장

## 사용 방법

1) ApplicationSet 생성/적용

```sh
./scripts/apply-applicationsets.sh
```

2) 상태 확인

```sh
kubectl get applicationsets -n argocd --context kkamji
kubectl get applications -n argocd --context kkamji
```

3) 배포 결과 확인(대상 네임스페이스: `kcd`)

```sh
kubectl get all -n kcd --context kcd-east
kubectl get all -n kcd --context kcd-west
```

## 포트포워딩

ApplicationSet은 Helm `releaseName=appset` 사용 -> Service 이름 `appset-kcd-2025`

```sh
# west 클러스터 예시
kubectl --context kcd-west -n kcd port-forward svc/appset-kcd-2025 8080:80

# east 클러스터 예시
kubectl --context kcd-east -n kcd port-forward svc/appset-kcd-2025 8080:80
```

## 정리/삭제

```sh
./delete-applicationsets.sh
```

- ApplicationSet 삭제, 생성된 `Application` 리소스도 `east`, `west`로 정리

## 구성 상세

주요 스펙은 다음과 같습니다.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: kcd-2025-appset-list
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - list:
        elements:
          - region: east
          - region: west
  template:
    metadata:
      name: 'kcd-2025-appset-{{ .region }}'
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: kcd-2025
      source:
        repoURL: https://github.com/KKamJi98/kcd-2025.git
        targetRevision: HEAD
        path: helm
        helm:
          releaseName: 'appset'
          parameters:
            - name: prefix
              value: kcd
            - name: region
              value: '{{ .region }}'
            - name: replicaCount
              value: "3"
      destination:
        name: 'kcd-{{ .region }}'
        namespace: kcd
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true
          - PrunePropagationPolicy=foreground
          - PruneLast=true
```

변경 포인트 가이드

- `source.repoURL`/`path`/`targetRevision`: 배포 소스 저장소/경로 환경에 맞게 조정
- `destination.name`: Argo CD 등록 대상 클러스터 이름(`kcd-east`/`kcd-west`)과 일치
- `project`: Argo CD `AppProject` 이름(`kcd-2025`), repo/대상 리소스 접근 권한 허용
- Helm 파라미터: `prefix`, `region`, `replicaCount` 배포 정책에 맞게 조정 가능

## 체크리스트

- ApplicationSet가 올바른 repo/path/branch 가리킴
- 자동 동기화(`automated + prune + selfHeal`) 활성화
- 네임스페이스 `kcd` 존재 또는 `CreateNamespace=true`로 자동 생성
- 동/서부 및 단계별 차이를 소스 값(Helm values)로 분리

## 트러블슈팅

- Application 상태 `OutOfSync` 지속: 대상 클러스터 접근 권한 또는 Helm 값 불일치 여부 확인
- `Project does not permit...` 오류: `AppProject`에 repoURL, 대상 클러스터(`destinations`), 네임스페이스 권한 추가
- 리소스 충돌/SSA 경고: `syncOptions`에 `ServerSideApply=true` 포함 여부 확인

## 참고

- 스크립트는 `--context kkamji` 사용. 로컬 kubeconfig 컨텍스트 이름이 다를 경우 스크립트 수정
- 비밀/자격 증명은 저장소에 커밋 금지, 외부 시크릿 매니저 또는 환경 변수 사용
