{{/*
  Druid on K8S
  Copyright (c) 2023-present NAVER Corp.
  Apache-2.0
*/}}
{{- define "common-runtime" }}
# Zookeeper
druid.zk.service.host={{ .Values.zookeeper.host }}:{{ .Values.zookeeper.clientPort }}
druid.zk.paths.base=/druid-on-k8s/{{ .Release.Name }}
druid.zk.service.compress=false

# Metadata Store
druid.metadata.storage.type={{ .Values.metadataStorage.type }}

{{- if eq .Values.metadataStorage.type "derby" }}
druid.metadata.storage.connector.connectURI=jdbc:derby://localhost:1527/druid/data/derbydb/metadata.db;create=true
druid.metadata.storage.connector.host=localhost
druid.metadata.storage.connector.port=1527
druid.metadata.storage.connector.createTables=true
{{- else }}
druid.metadata.storage.connector.connectURI={{ .Values.metadataStorage.connectURI }}/{{ regexReplaceAll "[-]" .Release.Name "_" }}?createDatabaseIfNotExist=true
druid.metadata.storage.connector.user={{ .Values.metadataStorage.user }}
druid.metadata.storage.connector.password={{ b64dec .Values.metadataStorage.password | trim }}
druid.metadata.storage.connector.createTables={{ .Values.metadataStorage.createTables }}
{{- if .Values.metadataStorage.driverClassName }}
druid.metadata.mysql.driver.driverClassName={{ .Values.metadataStorage.driverClassName }}
{{- end }}
{{- end }}




# Deep Storage
druid.storage.type={{ .Values.deepStorage.type }}
{{- if eq .Values.deepStorage.type "local" }}
druid.storage.storageDirectory=var/druid/segments
{{- end }}
{{- if eq .Values.deepStorage.type "hdfs" }}
druid.storage.storageDirectory=hdfs://{{.Values.hdfs.nameservice}}/druid-on-k8s/{{ .Release.Name }}/deepstorage
{{- end }}

#
# Extensions
#
druid.extensions.loadList=[{{ printf "\"%s\"" (join "\",\"" .Values.extensions) }}]

#
# Metric Emitter
#
druid.monitoring.emissionPeriod=PT1M
druid.monitoring.monitors=[{{ printf "\"%s\"" (join "\",\"" .Values.monitors.common) }}]
druid.emitter=prometheus
druid.emitter.prometheus.strategy=exporter
druid.emitter.prometheus.port={{ .Values.prometheus.port }}
druid.emitter.prometheus.dimensionMapPath=/opt/druid/conf/druid/cluster/_common/metricDimensions.json

#
# Service discovery
#
druid.selectors.indexing.serviceName=druid/overlord
druid.selectors.coordinator.serviceName=druid/coordinator

druid.indexer.logs.type={{ .Values.coordinators.indexer.logs.type }}
{{- if eq .Values.coordinators.indexer.logs.type "file" }}
druid.indexer.logs.directory=var/druid/indexing-logs
{{- end }}
{{- if eq .Values.coordinators.indexer.logs.type "hdfs" }}
druid.indexer.logs.directory=hdfs://{{.Values.hdfs.nameservice}}/druid-on-k8s/{{ .Release.Name }}/indexing-logs
# If true, delete old acquisition log files
# Execution cycle: druid.indexer.logs.kill.delay (default: 6 hours)
druid.indexer.logs.kill.enabled={{ .Values.coordinators.indexer.logs.retention.enabled }}
# durationToRetain: Delete log files older than this value (unit: ms)
druid.indexer.logs.kill.durationToRetain={{ mul .Values.coordinators.indexer.logs.retention.durationDays 24 60 60 1000 }}
{{- end }}


{{- if .Values.kerberos.enable }}
#
# Kerberos Setup
#
druid.hadoop.security.kerberos.principal={{ .Values.kerberos.user }}
druid.hadoop.security.kerberos.keytab=/etc/keytab/keytab
{{- end }}

{{- end }}
