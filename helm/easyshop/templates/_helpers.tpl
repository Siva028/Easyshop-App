{{/*
Expand the name of the chart.
*/}}
{{- define "easyshop.name" -}}
{{- .Chart.Name }}
{{- end }}

{{/*
Full name — used for all resource names
*/}}
{{- define "easyshop.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "easyshop.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "easyshop.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — used in Deployment + Service matchLabels
*/}}
{{- define "easyshop.selectorLabels" -}}
app.kubernetes.io/name: {{ include "easyshop.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
