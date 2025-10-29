{{- define "syncWave" -}}
{{- if .Values.syncWave }}argocd.argoproj.io/sync-wave: "{{ .Values.syncWave }}"{{- end -}}
{{- end -}}
