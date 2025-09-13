# Terraform Clusters

이 디렉토리는 클러스터별로 분리된 Terraform 구성을 포함

## 구조

- `clusters/kcd-east` – 동부 클러스터 전용 상태/리소스
- `clusters/kcd-west` – 서부 클러스터 전용 상태/리소스
- `clusters/kcd-argo` – Argo 클러스터 전용 상태/리소스
- `templates/` – 공용 템플릿(예: Pod Identity AssumeRole 정책)
- `update-kubeconfig.sh` – 3개 컨텍스트를 kubeconfig에 추가

## 요구 사항

- Terraform: >= 1.13 (테스트: v1.13.1, `.terraform-version`: 1.13.2)
- AWS CLI: v2.30.1
- Helm: v3.16.2
- kubectl: 1.28+
- Terraform Cloud Org `kkamji-lab`
  - Remote State Workspace: `basic` (VPC, Subnet, Key 등 참조)

## 사용 방법

각 클러스터 디렉토리에서 개별적으로 초기화/계획/적용

```bash
terraform login
cd clusters/kcd-east
terraform init
terraform plan
terraform apply

cd ../kcd-west
terraform init && terraform apply

cd ../kcd-argo
terraform init && terraform apply
```

## 일괄 실행

3개 클러스터를 한 번에 plan/apply하려면 스크립트 사용

```bash
# 전체 클러스터(plan)
bash clusters/run-all.sh plan

# 전체 클러스터(apply, 자동 승인)
bash clusters/run-all.sh apply --yes

# 특정 클러스터만(plan)
bash clusters/run-all.sh plan --clusters kcd-east,kcd-west

# 플러그인 업그레이드 포함(init -upgrade 후 실행)
bash clusters/run-all.sh apply --yes --upgrade
```

## 변수

- `region`: 기본값 `ap-northeast-2`
- `access_entries`: Access Entry 맵(선택), caller 전역 권한은 기본 제공

## kubeconfig

```bash
../update-kubeconfig.sh
kubectl config get-contexts
```

## 구성 공통 사항

- EKS 모듈 `terraform-aws-modules/eks/aws ~> 21.0`
- Kubernetes `1.33`
- 노드그룹 `t4g.small` 2대 고정, `maxPods: 110`
- 애드온: `coredns`, `kube-proxy`, `vpc-cni(프리픽스 위임)`, `aws-ebs-csi-driver(Pod Identity)`, `metrics-server`, `external-dns(Pod Identity)`, `snapshot-controller`
- 네트워킹: 원격 상태(`basic`)의 `vpc_id`, `public_subnet_ids`, `key_pair_name`

## Helm 추가 구성 및 클러스터 차이

- 공통(west/east/argo): `aws-load-balancer-controller` eks-charts 배포(차트 버전 `1.13.0`)
  - 서비스어카운트와 EKS Pod Identity 사용, 정책은 `templates/aws_load_balancer_policy.json` 사용
  - 차트 값 `clusterName`은 각 클러스터 이름으로 설정
- kcd-argo 전용: Argo CD를 argo-helm 차트(`argo-cd`)로 배포(차트 `8.3.1`, App `v3.1.1`)
  - 네임스페이스 `argocd`, Ingress는 ALB 클래스로 구성
  - 도메인 `argocd-kcd.kkamji.net`, ACM 인증서 ARN 적용
  - 나머지 기본 구성은 kcd-east, kcd-west와 동일
