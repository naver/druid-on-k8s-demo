{{/*
  Druid on K8S
  Copyright (c) 2023-present NAVER Corp.
  Apache-2.0
*/}}
{{- define "coordinator" }}
nodeType: "coordinator"
druid.port: {{ .Values.druid.port }}
ports:
  - name: prometheus
    containerPort: {{ .Values.prometheus.port }}
nodeConfigMountPath: "/opt/druid/conf/druid/cluster/master/coordinator-overlord"
replicas: {{ .Values.coordinators.replicas }}
log4j.config: |-
  {{- include "log4j.config" (merge (dict "role" "coordinator") .) | indent 4 }}
resources:
  limits:
    cpu: {{ .Values.coordinators.resources.limits.cpu | quote }}
    memory: {{ .Values.coordinators.resources.limits.memory }}
    ephemeral-storage: {{ .Values.coordinators.resources.limits.ephemeralStorage }}
  requests:
    cpu: {{ .Values.coordinators.resources.requests.cpu | quote }}
    memory: {{ .Values.coordinators.resources.requests.memory }}
    ephemeral-storage: {{ .Values.coordinators.resources.requests.ephemeralStorage }}
podDisruptionBudgetSpec:
  maxUnavailable: 1
runtime.properties: |
  druid.service=druid/coordinator

  # HTTP server threads
  druid.coordinator.startDelay=PT30S
  druid.coordinator.period={{ .Values.coordinators.period }}

  # Configure this coordinator to also run as Overlord
  druid.coordinator.asOverlord.enabled={{ .Values.coordinators.enableOverlord }}
  druid.coordinator.asOverlord.overlordService=druid/overlord
  druid.indexer.queue.startDelay=PT30S
  druid.indexer.runner.type={{ .Values.coordinators.indexer.runnerType }}
  druid.indexer.storage.type=metadata

  {{- if .Values.monitors.coordinators }}
  # monitoring
  druid.monitoring.monitors=[{{ printf "\"%s\"" (join "\",\"" (concat .Values.monitors.common .Values.monitors.coordinators)) }}]
  {{- end }}
extra.jvm.options: |-
  -Xmx{{ .Values.coordinators.jvmOptions.maxHeapSize }}
  -Xms{{ .Values.coordinators.jvmOptions.minHeapSize }}
affinity:
  podAntiAffinity:
   preferredDuringSchedulingIgnoredDuringExecution:
     - weight: 100
       podAffinityTerm:
         labelSelector:
           matchLabels:
             "druid_cr": {{ .Release.Name }}
             "component": "coordinator"
         topologyKey: "kubernetes.io/hostname"
{{- end }}
