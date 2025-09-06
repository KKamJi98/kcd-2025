# Helm 프롬프트 모음

Helm 차트 작성과 유지보수를 위한 프롬프트 템플릿과 체크리스트입니다.

## 목표

- 차트 일관성 유지와 재사용성 극대화
- Kubernetes 1.28+ 기준 호환성 확보
- 값 파일 중심 구성과 안전한 기본값 제공

## 현재 리포지토리 참고

- `helm/Chart.yaml`, `helm/values.yaml`
- `helm/templates/*.yaml`
- `helm/kcd_east_values.yaml`, `helm/kcd_west_values.yaml`
- `helm/deploy-helm-charts.sh`

## 베스트 프랙티스

- Chart
  - `version`(차트 버전)과 `appVersion`은 분리하고 SemVer 준수
  - 공통 라벨: `app.kubernetes.io/name`, `instance`, `version`, `managed-by`, `part-of`
  - `_helpers.tpl`에 공통 라벨/네이밍 헬퍼 정의 후 `include`로 사용
- Values
  - 모든 템플릿 값은 `.Values`로 주입, 안전한 기본값 제공(`default` 함수 활용)
  - 민감정보는 값 파일에 두지 말고 별도 시크릿/외부 주입 사용
- Templates
  - API 버전은 `apps/v1` 등 현행 버전 사용, 필요 시 `.Capabilities`로 분기
  - `securityContext`(pod/container), `readinessProbe`/`livenessProbe`, `resources` 지정
  - `Service`, `Ingress`는 타입/클래스/호스트를 값으로 제어 가능하게 구성
  - 조건부 렌더링 시 `if`, `with` 사용, 공백/들여쓰기 주의(`nindent`, `toYaml`)
- 릴리스 및 검증
  - `helm lint`, `helm template`로 렌더 결과 점검
  - 환경별 값 파일(`kcd_east_values.yaml`, `kcd_west_values.yaml`)로 배포 분리

## 검증 체크리스트

- [ ] `helm lint` 경고/오류 없음
- [ ] 템플릿 렌더가 Kubernetes 1.28+에서 유효
- [ ] 모든 컨테이너에 `resources`/프로브/보안컨텍스트 설정
- [ ] 공통 라벨이 모든 리소스에 적용
- [ ] 값 파일만으로 환경 차이를 표현 가능

## 예시 프롬프트

다음 요구를 충족하도록 `helm/` 차트를 수정해 주세요.

1) 모든 리소스에 공통 라벨을 추가하고 `_helpers.tpl`에 헬퍼를 정의합니다.
2) `Deployment`에 `readinessProbe`, `livenessProbe`, `resources`의 기본값을 `values.yaml`로 이동합니다.
3) `Ingress`의 클래스명과 호스트를 값으로 제어 가능하게 하고 기본은 비활성화합니다.
4) `helm lint`가 통과되도록 템플릿을 정리합니다.

출력: 변경된 파일 패치(diff), 적용 방법, `helm template` 검증 명령.

