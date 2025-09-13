# 데모 실행 가이드(명령어)

Terraform -> kubeconfig -> Argo CD 등록 -> Project -> Declarative -> App-of-Apps -> ApplicationSet 순서로 진행합니다

## 준비물

- AWS CLI v2 로그인 및 권한 준비(해당 계정/리전)
- Terraform ≥ 1.5, `kubectl` ≥ 1.28, `helm` ≥ 3.12, Argo CD CLI
- 리전: `ap-northeast-2`

> 참고: Argo CD Ingress에 사용할 와일드카드 인증서가 필요하면 `terraform/clusters/kcd-acm`을 먼저 적용 

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
