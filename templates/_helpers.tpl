{{- define "nifi-registry.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "nifi-registry.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "nifi.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "nifi.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}
