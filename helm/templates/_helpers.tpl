{{- define "kcd-2025-nginx.name" -}}
{{- /* 차트 기본 이름에서 '-nginx' 접미사를 제거하여 베이스 이름 통일 */ -}}
{{- $base := default .Chart.Name .Values.nameOverride -}}
{{- $trimmed := trimSuffix "-nginx" $base -}}
{{- $trimmed | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kcd-2025-nginx.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- $name = trimSuffix "-nginx" $name -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "kcd-2025-nginx.labels" -}}
app.kubernetes.io/name: {{ include "kcd-2025-nginx.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
