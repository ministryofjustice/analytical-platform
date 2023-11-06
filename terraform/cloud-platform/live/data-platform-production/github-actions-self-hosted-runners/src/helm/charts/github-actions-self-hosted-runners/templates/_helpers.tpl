{{- define "github.repoShorthand" }}
{{- if eq "moj-analytical-services" .Values.github.organisation }}
{{- printf "%s" "moj"}}
{{- else -}}
{{- printf "%s" "mojas"}}
{{- end -}}
{{- end }}
