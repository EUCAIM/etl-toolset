
{{- define "nifi.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "nifi.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "platform.persistent_home.mount_point" -}}
/home/ds/persistent-home
{{- end }}

{{- define "platform.persistent_shared_folder.mount_point" -}}
/home/ds/persistent-shared-folder
{{- end }}

{{- define "platform.datasets.mount_point" -}}
/home/ds/datasets
{{- end }}

{{/* Print a random string (useful for generate passwords). */}}
{{- define "utils.randomString" -}}
{{- randAlphaNum 20 -}}
{{- end }}
