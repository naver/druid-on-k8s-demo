{{/*
  Druid on K8S
  Copyright (c) 2023-present NAVER Corp.
  Apache-2.0
*/}}
{{- define "broker" }}
nodeType: "broker"
# Optionally specify for broker nodes
# imagePullSecrets:
# - name: tutu
druid.port: {{ .Values.druid.port }}
ports:
  - name: prometheus
    containerPort: {{ .Values.prometheus.port }}
nodeConfigMountPath: "/opt/druid/conf/druid/cluster/query/broker"
replicas: {{ .Values.brokers.replicas }}
log4j.config: |-
  {{- include "log4j.config" (merge (dict "role" "broker") .) | indent 4 }}
resources:
  limits:
    cpu: {{ .Values.brokers.resources.limits.cpu | quote }}
    memory: {{ .Values.brokers.resources.limits.memory }}
    ephemeral-storage: {{ .Values.brokers.resources.limits.ephemeralStorage }}
  requests:
    cpu: {{ .Values.brokers.resources.requests.cpu | quote }}
    memory: {{ .Values.brokers.resources.requests.memory }}
    ephemeral-storage: {{ .Values.brokers.resources.requests.ephemeralStorage }}
runtime.properties: |
  druid.service=druid/broker
  # HTTP server threads
  druid.broker.http.numConnections={{ .Values.brokers.http.numConnections }}
  druid.server.http.numThreads={{ .Values.brokers.http.numThreads }}
  druid.sql.enable={{ .Values.brokers.enableSql }}
  {{- if .Values.monitors.brokers }}
  # monitoring
  druid.monitoring.monitors=[{{ printf "\"%s\"" (join "\",\"" (concat .Values.monitors.common .Values.monitors.brokers)) }}]
  {{- end }}
extra.jvm.options: |-
  -Xmx{{ .Values.brokers.jvmOptions.maxHeapSize }}
  -Xms{{ .Values.brokers.jvmOptions.minHeapSize }}
  -XX:MaxDirectMemorySize={{ .Values.brokers.jvmOptions.maxDirectMemorySize }}
affinity:
  podAntiAffinity:
   preferredDuringSchedulingIgnoredDuringExecution:
     - weight: 100
       podAffinityTerm:
         labelSelector:
           matchLabels:
             "druid_cr": {{ .Release.Name }}
             "component": "broker"
         topologyKey: "kubernetes.io/hostname"
{{- end }}
