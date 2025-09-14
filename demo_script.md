# Demo Script

Terraform -> Update Kubeconfig -> Argo CD login & Cluster Add -> Project 생성 -> Declarative -> App-of-Apps -> ApplicationSet 순서로 진행

## 1) Terraform으로 클러스터 생성

```bash
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

## 2) kubeconfig 업데이트(컨텍스트 등록)

```bash
aws eks update-kubeconfig --region ap-northeast-2 --name kcd-east --alias kcd-east
aws eks update-kubeconfig --region ap-northeast-2 --name kcd-west --alias kcd-west
aws eks update-kubeconfig --region ap-northeast-2 --name kcd-argo --alias kcd-argo

kubectl config get-contexts
kubectl --context kcd-argo -n argocd get pods
```

## 3) Argo CD 로그인 및 대상 클러스터 등록

```bash
kubectl --context kcd-argo -n argocd get secrets argocd-initial-admin-secret -o yaml | yq .data.password | base64 -d
argocd login kcd-argo.kkamji.net --username admin --grpc-web
# 비밀번호 입력(초기 패스워드 또는 설정한 값)

argocd cluster add kcd-west -y
argocd cluster add kcd-east -y

argocd cluster list
```

## 4) AppProject 생성

```bash
kubectl --context kcd-argo -n argocd apply -f argocd/projects/kcd-2025.yaml
kubectl --context kcd-argo -n argocd get appprojects
```

## 5) Declarative Applications 적용

```bash
kubectl --context kcd-argo -n argocd apply -f argocd/declarative_application/west-application.yaml
kubectl --context kcd-argo -n argocd apply -f argocd/declarative_application/east-application.yaml

kubectl --context kcd-argo -n argocd get applications

# 리소스 확인
watch kubectl --context kcd-west -n kcd get deploy,svc,pods
watch kubectl --context kcd-east -n kcd get deploy,svc,pods

# 포트포워딩(8080/8081 -> 80)
kubectl --context kcd-west -n kcd port-forward svc/declarative-kcd-2025 8080:80
kubectl --context kcd-east -n kcd port-forward svc/declarative-kcd-2025 8081:80
```

## 6) App of Apps 적용

```bash
kubectl --context kcd-argo -n argocd apply -f argocd/app-of-apps/west-root-application.yaml
kubectl --context kcd-argo -n argocd apply -f argocd/app-of-apps/east-root-application.yaml

kubectl --context kcd-argo -n argocd get applications
```

## 7) ApplicationSet 적용

```bash
kubectl --context kcd-argo -n argocd apply -f argocd/application-set/kcd-2025-appset-list.yaml
kubectl --context kcd-argo -n argocd get applicationsets
kubectl --context kcd-argo -n argocd get applications
```

## 8) 배포 검증 및 포트포워딩(예시)

```bash
# 리소스 확인
kubectl --context kcd-west -n kcd get deploy,svc,pods
kubectl --context kcd-east -n kcd get deploy,svc,pods

# 포트포워딩(8080/8081 -> 80)
kubectl --context kcd-west -n kcd port-forward svc/declarative-kcd-2025 8080:80
kubectl --context kcd-east -n kcd port-forward svc/declarative-kcd-2025 8081:80
```

## 정리(옵션)

```bash
# Declarative / App-of-Apps / ApplicationSet 순서로 리소스 삭제
kubectl --context kcd-argo -n argocd delete -f argocd/application-set/kcd-2025-appset-list.yaml --ignore-not-found
kubectl --context kcd-argo -n argocd delete -f argocd/app-of-apps/west-root-application.yaml --ignore-not-found
kubectl --context kcd-argo -n argocd delete -f argocd/app-of-apps/east-root-application.yaml --ignore-not-found
kubectl --context kcd-argo -n argocd delete -f argocd/declarative_application/west-application.yaml --ignore-not-found
kubectl --context kcd-argo -n argocd delete -f argocd/declarative_application/east-application.yaml --ignore-not-found
```
