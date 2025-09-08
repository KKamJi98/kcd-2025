# Argo CD ApplicationSet

이 디렉터리는 Argo CD ApplicationSet으로 동/서부 지역(east/west)에 따라 Helm 차트를 반복적으로 배포하기 위한 선언과 스크립트를 포함합니다.

## 개요

- 리소스: `ApplicationSet` 1개가 2개의 `Application`(east, west)을 생성합니다.
- 동기화: 자동 동기화(`automated`) + `prune` + `selfHeal` 활성화로 GitOps 일관성을 유지합니다.
- 템플릿: Go 템플릿(`goTemplate`)을 사용해 `region` 변수를 바인딩합니다.

## 구성 파일

- `kcd-2025-appset-list.yaml`: ApplicationSet 선언(생성 대상 목록, 템플릿, 동기화 정책).
- `scripts/apply-applicationsets.sh`: ApplicationSet 생성/적용 스크립트.
- `scripts/delete-applicationsets.sh`: ApplicationSet 및 생성된 Application 정리 스크립트.

## 전제 조건

- Argo CD가 설치되어 있고 `argocd` 네임스페이스에서 동작 중일 것.
- Argo CD `AppProject` 이름 `kcd-2025`가 존재하고 해당 리포지토리/경로/대상 클러스터에 대한 권한이 설정되어 있을 것.
- kubeconfig에 `kkamji` 컨텍스트와 대상 클러스터 이름 `kcd-east`, `kcd-west`가 구성되어 있을 것.
- Kubernetes 1.28+ 및 Argo CD 2.8+ 권장.

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

ApplicationSet은 Helm `releaseName=appset`을 사용하므로 Service 이름은 `appset-kcd-2025`입니다.

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

- ApplicationSet을 삭제하고, 생성된 `Application` 리소스도 `east`, `west`로 정리합니다.

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

변경 포인트 가이드:

- `source.repoURL`/`path`/`targetRevision`: 배포 소스 저장소와 경로를 환경에 맞게 조정하세요.
- `destination.name`: Argo CD에 등록된 대상 클러스터 이름(`kcd-east`/`kcd-west`)과 일치해야 합니다.
- `project`: Argo CD `AppProject` 이름(`kcd-2025`). 리포지토리와 대상 리소스 접근 권한을 허용해야 합니다.
- Helm 파라미터: `prefix`, `region`, `replicaCount`는 배포 정책에 맞게 조정 가능합니다.

## 체크리스트

- ApplicationSet가 올바른 repo/path/branch를 가리킵니다.
- 자동 동기화(`automated + prune + selfHeal`)가 활성화되어 있습니다.
- 네임스페이스 `kcd`가 존재하거나 `CreateNamespace=true`로 자동 생성됩니다.
- 동/서부 및 단계별 차이가 소스 값(Helm values)로 분리되어 있습니다.

## 트러블슈팅

- Application 상태 `OutOfSync` 지속: 대상 클러스터 접근 권한 또는 Helm 값 불일치 여부를 확인합니다.
- `Project does not permit...` 오류: `AppProject`에 repoURL, 대상 클러스터(`destinations`), 네임스페이스 권한을 추가하세요.
- 리소스 충돌/SSA 경고: `syncOptions`에 `ServerSideApply=true`가 포함되어 있는지 확인하세요.

## 참고

- 스크립트는 `--context kkamji`를 사용합니다. 로컬 kubeconfig의 컨텍스트 이름과 다를 경우 스크립트를 수정하세요.
- 비밀/자격 증명은 저장소에 커밋하지 말고 외부 시크릿 매니저 또는 환경 변수를 사용하세요.
