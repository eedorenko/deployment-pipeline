{{- define "gitopsName" -}}
{{ print  .Values.project "-" .Values.deploymentTarget }}
{{end}}