## 1. Manual Application Spec

```bash
##################################
# Argo CD Web UI 접속
##################################
open https://kcd-argo.kkamji.net/

##################################
# Git Repo URL
##################################
repoURL: https://github.com/KKamJi98/kcd-2025.git

##################################
# Applications 확인
##################################
kubectl --context kcd-argo -n argocd get applications
```

## 2) Declarative Applications 적용

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
# Applications 확인
##################################
kubectl --context kcd-argo -n argocd get applications

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

##################################
# 정리: Declarative Applications 삭제 (디렉터리 스크립트 사용)
##################################
./argocd/declarative_application/scripts/delete-applications.sh
```

## 3) App of Apps 적용

```bash
##################################
# Argo CD 확인
##################################
open https://kcd-argo.kkamji.net/

##################################
# root application 생성
##################################
kubectl --context kcd-argo -n argocd apply -f argocd/app-of-apps/west-root-application.yaml
kubectl --context kcd-argo -n argocd apply -f argocd/app-of-apps/east-root-application.yaml

##################################
# Applications 확인
##################################
kubectl --context kcd-argo -n argocd get applications

##################################
# 정리: App-of-Apps 삭제
##################################
./argocd/app-of-apps/scripts/delete-applications.sh
```

## 4) ApplicationSet 적용

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
# ApplicationSet & ApplicationsSet 확인
##################################
kubectl --context kcd-argo -n argocd get applicationsets
kubectl --context kcd-argo -n argocd get applications

##################################
# 정리: ApplicationSet 삭제 (디렉터리 스크립트 사용)
##################################
./argocd/application-set/scripts/delete-applicationsets.sh
```
