# Terraform Clusters

이 디렉토리는 클러스터별로 분리된 Terraform 구성을 포함합니다.

## 구조

- `clusters/kcd-east` – 동부 클러스터 전용 상태/리소스
- `clusters/kcd-west` – 서부 클러스터 전용 상태/리소스
- `clusters/kcd-argo` – Argo 클러스터 전용 상태/리소스
- `templates/` – 공용 템플릿(예: Pod Identity AssumeRole 정책)
- `update-kubeconfig.sh` – 3개 컨텍스트를 kubeconfig에 추가

## 요구 사항

- Terraform `>= 1.5.0`
- AWS CLI v2, `kubectl`, `helm`
- Terraform Cloud Org `kkamji-lab`
  - Remote State Workspace: `basic` (VPC, Subnet, Key 등 참조)

## 사용 방법

각 클러스터 디렉토리에서 개별적으로 초기화/계획/적용합니다.

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
