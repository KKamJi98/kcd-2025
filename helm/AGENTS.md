# kcd-2025 Demo 저장용 Nginx

해당 저장소는 Cloud Native Korea Community Day 2025(kcd-2025) 에 사용될 Demo Helm Chart 저장소입니다.

## Helm Chart 개요

1. Basic 한 Helm Chart를 생성하는데 Nginx 이미지를 사용하고 ConfigMap을 사용해서 web root directory에 사용자가 원하는 출력을 보여줘야 합니다.
2. 환경변수를 기반으로 아래 `[kcd-west]`에 대한 내용에서 west나 east로 Helm Values를 통해 제어할 수 있어야 합니다.
3. Nginx 에 넣을 HTML 디자인은 최대한 깔끔하고 정갈해야 합니다.
4. 출력될 문구는 가운데에 위치해야합니다
5. nginx pod 이미지는 `nginx:stable-alpine3.21-perl` 를 사용합니다.
6. 리소스는 Deployment, Service, ConfigMap 으로 구성

## 출력

```md
[kcd-west] Cloud Native Korea Community Day 2025 에 오신것을 환영합니다!
```
