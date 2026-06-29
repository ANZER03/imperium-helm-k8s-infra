{{/*
Expand the name of the chart.
*/}}
{{- define "kafka-connect-connectors.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kafka-connect-connectors.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "kafka-connect-connectors.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common Debezium PostgreSQL connector config shared across all connectors.
Usage: include "kafka-connect-connectors.pgConfig" . 
*/}}
{{- define "kafka-connect-connectors.pgConfig" -}}
database.hostname: {{ .Values.postgres.host | quote }}
database.port: {{ .Values.postgres.port | quote }}
database.user: {{ .Values.postgres.user | quote }}
database.password: ${file:/opt/kafka/external-configuration/debezium-creds/password}
database.dbname: {{ .Values.postgres.database | quote }}
plugin.name: pgoutput
connector.class: io.debezium.connector.postgresql.PostgresConnector
publication.autocreate.mode: "disabled"
tombstones.on.delete: "false"
heartbeat.interval.ms: "10000"
{{- end }}
