{{/*
Expand the name of the chart.
*/}}
{{- define "uyuni-suite.name" -}}
{{- default .Chart.Name .Values.uyuni.common.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "uyuni-suite.fullname" -}}
{{- if .Values.uyuni.common.fullnameOverride }}
{{- .Values.uyuni.common.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.uyuni.common.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "uyuni-suite.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "uyuni-suite.labels" -}}
helm.sh/chart: {{ include "uyuni-suite.chart" . }}
{{ include "uyuni-suite.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "uyuni-suite.selectorLabels" -}}
app.kubernetes.io/name: {{ include "uyuni-suite.name" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "uyuni-suite.serviceAccountName" -}}
{{- if .Values.uyuni.common.serviceAccount.create }}
{{- default (include "uyuni-suite.fullname" .) .Values.uyuni.common.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.uyuni.common.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the env vars to use
*/}}
{{- define "uyuni-suite.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}