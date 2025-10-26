{{- define "pyservice.name" -}}{{ .Chart.Name }}{{- end -}}
{{- define "pyservice.fullname" -}}{{ include "pyservice.name" . }}{{- end -}}
