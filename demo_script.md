# Demo Script

Terraform -> Update Kubeconfig -> Argo CD login & Cluster Add -> Project 생성 -> Declarative -> App-of-Apps -> ApplicationSet 순서로 진행

## 1) Terraform으로 클러스터 생성

```bash
##################################
# Terraform Login 및 EKS Cluster Provisioning
##################################
terraform login

cd terraform/clusters/kcd-east
terraform init
terraform apply -auto-approve

cd ../kcd-west
terraform init
terraform apply -auto-approve

cd ../kcd-argo
terraform init
terraform apply -auto-approve
```

## 2) 예비 alias

```bash
##################################
# alias 설정
##################################
alias kwest='kubectl --context kcd-west'
alias keast='kubectl --context kcd-east'
alias kargo='kubectl --context kcd-argo'
```

## 3) kubeconfig 업데이트(컨텍스트 등록)

```bash
aws eks update-kubeconfig --region ap-northeast-2 --name kcd-east --alias kcd-east
aws eks update-kubeconfig --region ap-northeast-2 --name kcd-west --alias kcd-west
aws eks update-kubeconfig --region ap-northeast-2 --name kcd-argo --alias kcd-argo

kubectl config get-contexts
kubectl --context kcd-argo -n argocd get pods
```

## 4) Argo CD 로그인 및 대상 클러스터 등록

```bash
##################################
# ArgoCD 초기비밀번호 확인
##################################
kubectl --context kcd-argo -n argocd get secrets argocd-initial-admin-secret -o yaml | yq '.data.password' | base64 -d; echo

##################################
# ArgoCD 비밀번호 변경
##################################
open https://kcd-argo.kkamji.net

##################################
# ArgoCD CLI 로그인
##################################
argocd login kcd-argo.kkamji.net --username admin --grpc-web
# 비밀번호 입력(초기 패스워드 또는 설정한 값)

##################################
# ArgoCD Cluster 추가 및 리스트 확인
##################################
argocd cluster add kcd-west -y
argocd cluster add kcd-east -y

argocd cluster list
```

## 5) AppProject 생성

```bash
##################################
# AppProject 생성
##################################
kubectl --context kcd-argo -n argocd apply -f argocd/projects/kcd-2025.yaml

##################################
# AppProject 확인
##################################
kubectl --context kcd-argo -n argocd get appprojects
```

## 6) Declarative Applications 적용

```bash
##################################
# Argo CD 확인
##################################
open https://kcd-argo.kkamji.net/

##################################
# watch로 지속 확인 (지속)
##################################
watch kubectl --context kcd-west -n kcd get pods
watch kubectl --context kcd-east -n kcd get pods

##################################
# application 생성
##################################
kubectl --context kcd-argo -n argocd apply -f argocd/declarative_application/west-application.yaml
kubectl --context kcd-argo -n argocd apply -f argocd/declarative_application/east-application.yaml

##################################
# application 확인
##################################
argocd app list | grep kcd-2025

##################################
# 접속 확인
##################################
# 8080(west) - 8081(east)
kubectl --context kcd-west -n kcd port-forward svc/declarative-kcd-2025 8080:80 &
kubectl --context kcd-east -n kcd port-forward svc/declarative-kcd-2025 8081:80 &

open http://localhost:8080
open http://localhost:8081

##################################
# 포트포워딩 중지
##################################
pkill kubectl

# 정리: Declarative Applications 삭제 (디렉터리 스크립트 사용)
./argocd/declarative_application/scripts/delete-applications.sh
```

## 7) App of Apps 적용

```bash
##################################
# Argo CD 확인
##################################
open https://kcd-argo.kkamji.net/

##################################
# watch로 지속 확인 (지속)
##################################
watch kubectl --context kcd-west -n kcd get pods
watch kubectl --context kcd-east -n kcd get pods

##################################
# root application 생성
##################################
kubectl --context kcd-argo -n argocd apply -f argocd/app-of-apps/west-root-application.yaml
kubectl --context kcd-argo -n argocd apply -f argocd/app-of-apps/east-root-application.yaml

kubectl --context kcd-argo -n argocd get applications

##################################
# application 확인
##################################
argocd app list | grep kcd-2025

# 정리: App-of-Apps 삭제 (디렉터리 스크립트 사용)
./argocd/app-of-apps/scripts/delete-applications.sh
```

## 8) ApplicationSet 적용

```bash
##################################
# Argo CD 확인
##################################
open https://kcd-argo.kkamji.net/

##################################
# watch로 지속 확인 (지속)
##################################
watch kubectl --context kcd-west -n kcd get pods
watch kubectl --context kcd-east -n kcd get pods

##################################
# ApplicationSet 배포
##################################
kubectl --context kcd-argo -n argocd apply -f argocd/application-set/kcd-2025-appset-list.yaml

##################################
# ApplicationSet 확인
##################################
kubectl --context kcd-argo -n argocd get applicationsets
kubectl --context kcd-argo -n argocd get applications
argocd app list | grep appset

# 정리: ApplicationSet 삭제 (디렉터리 스크립트 사용)
./argocd/application-set/scripts/delete-applicationsets.sh
```










## 정리(옵션)

```bash
# 현재 Application / ApplicationSet 상태 확인
kubectl --context kcd-argo -n argocd get applications
kubectl --context kcd-argo -n argocd get applicationsets
argocd app list

# Declarative / App-of-Apps / ApplicationSet 순서로 리소스 삭제
kubectl --context kcd-argo -n argocd delete -f argocd/application-set/kcd-2025-appset-list.yaml --ignore-not-found
kubectl --context kcd-argo -n argocd delete -f argocd/app-of-apps/west-root-application.yaml --ignore-not-found
kubectl --context kcd-argo -n argocd delete -f argocd/app-of-apps/east-root-application.yaml --ignore-not-found
kubectl --context kcd-argo -n argocd delete -f argocd/declarative_application/west-application.yaml --ignore-not-found
kubectl --context kcd-argo -n argocd delete -f argocd/declarative_application/east-application.yaml --ignore-not-found

# 삭제 후 상태 재확인
kubectl --context kcd-argo -n argocd get applications || true
kubectl --context kcd-argo -n argocd get applicationsets || true
argocd app list || true
```

다음 스크립트로 일괄/문제 상황 정리를 수행

- 전체 삭제 일괄 실행: `./argocd/scripts/delete-all-apps.sh`
  - ApplicationSet → App-of-Apps → Declarative 순으로 내부 스크립트를 호출해 정리
- finalizer 때문에 삭제가 막힐 때: `./argocd/scripts/delete-finalizers.sh`
  - 기본값은 `NAMESPACE=argocd`, `CTX=kcd-argo`
  - ex: `NAMESPACE=argocd CTX=kcd-argo ./argocd/scripts/delete-finalizers.sh`
