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

# 확인 명령어
argocd app list | grep kcd-2025
argocd app get kcd-2025-west
argocd app get kcd-2025-east

# watch로 지속 확인
watch -n 2 'kubectl --context kcd-argo -n argocd get applications'
watch -n 2 'argocd app list | grep kcd-2025'

# 리소스 확인
watch kubectl --context kcd-west -n kcd get pods
watch kubectl --context kcd-east -n kcd get pods

# 포트포워딩(8080/8081 -> 80)
kubectl --context kcd-west -n kcd port-forward svc/declarative-kcd-2025 8080:80
kubectl --context kcd-east -n kcd port-forward svc/declarative-kcd-2025 8081:80

# 정리: Declarative Applications 삭제 (디렉터리 스크립트 사용)
./argocd/declarative_application/scripts/delete-applications.sh
```

## 6) App of Apps 적용

```bash
kubectl --context kcd-argo -n argocd apply -f argocd/app-of-apps/west-root-application.yaml
kubectl --context kcd-argo -n argocd apply -f argocd/app-of-apps/east-root-application.yaml

kubectl --context kcd-argo -n argocd get applications

# 확인 명령어
argocd app list | grep kcd-2025-root
argocd app get kcd-2025-root-west
argocd app get kcd-2025-root-east

# watch로 지속 확인
watch -n 2 'kubectl --context kcd-argo -n argocd get applications'
watch -n 2 'argocd app list | grep kcd-2025'

# 리소스 확인 (동/서부 클러스터)
watch kubectl --context kcd-west -n kcd get pods
watch kubectl --context kcd-east -n kcd get pods

# 정리: App-of-Apps 삭제 (디렉터리 스크립트 사용)
./argocd/app-of-apps/scripts/delete-applications.sh
```

## 7) ApplicationSet 적용

```bash
kubectl --context kcd-argo -n argocd apply -f argocd/application-set/kcd-2025-appset-list.yaml
kubectl --context kcd-argo -n argocd get applicationsets
kubectl --context kcd-argo -n argocd get applications

# 확인 명령어
argocd app list | grep appset
argocd app get kcd-2025-appset-east
argocd app get kcd-2025-appset-west

# watch로 지속 확인
watch -n 2 'kubectl --context kcd-argo -n argocd get applicationsets'
watch -n 2 'kubectl --context kcd-argo -n argocd get applications'
watch -n 2 'argocd app list | grep appset'

# 리소스 확인 (동/서부 클러스터)
watch kubectl --context kcd-west -n kcd get pods
watch kubectl --context kcd-east -n kcd get pods

# 포트포워딩(예시, 8080/8081 -> 80)
kubectl --context kcd-west -n kcd port-forward svc/appset-kcd-2025 8080:80
kubectl --context kcd-east -n kcd port-forward svc/appset-kcd-2025 8081:80

# 정리: ApplicationSet 삭제 (디렉터리 스크립트 사용)
./argocd/application-set/scripts/delete-applicationsets.sh
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
