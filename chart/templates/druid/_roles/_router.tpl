{{/*
  Druid on K8S
  Copyright (c) 2023-present NAVER Corp.
  Apache-2.0
*/}}
{{- define "router" }}
nodeType: "router"
druid.port: {{ .Values.druid.port }}
ports:
  - name: prometheus
    containerPort: {{ .Values.prometheus.port }}
nodeConfigMountPath: "/opt/druid/conf/druid/cluster/query/router"
replicas: {{ .Values.routers.replicas }}
log4j.config: |-
  {{- include "log4j.config" (merge (dict "role" "router") .) | indent 4 }}
resources:
  limits:
    cpu: {{ .Values.routers.resources.limits.cpu | quote }}
    memory: {{ .Values.routers.resources.limits.memory }}
    ephemeral-storage: {{ .Values.routers.resources.limits.ephemeralStorage }}
  requests:
    cpu: {{ .Values.routers.resources.requests.cpu | quote }}
    memory: {{ .Values.routers.resources.requests.memory }}
    ephemeral-storage: {{ .Values.routers.resources.requests.ephemeralStorage }}
runtime.properties: |
  druid.service=druid/router

  # HTTP proxy
  druid.router.http.numConnections={{ .Values.routers.http.numConnections }}
  druid.router.http.readTimeout={{ .Values.routers.http.readTimeout }}
  druid.router.http.numMaxThreads={{ .Values.routers.http.numMaxThreads }}
  druid.server.http.numThreads={{ .Values.routers.http.numThreads }}

  # Service discovery
  druid.router.defaultBrokerServiceName=druid/broker
  druid.router.coordinatorServiceName=druid/coordinator

  # Management proxy to coordinator / overlord: required for unified web console.
  druid.router.managementProxy.enabled=true

  {{- if .Values.monitors.routers }}
  # monitoring
  druid.monitoring.monitors=[{{ printf "\"%s\"" (join "\",\"" (concat .Values.monitors.common .Values.monitors.routers)) }}]
  {{- end }}
extra.jvm.options: |-
  -Xmx{{ .Values.routers.jvmOptions.maxHeapSize }}
  -Xms{{ .Values.routers.jvmOptions.minHeapSize }}
affinity:
  podAntiAffinity:
   preferredDuringSchedulingIgnoredDuringExecution:
     - weight: 100
       podAffinityTerm:
         labelSelector:
           matchLabels:
             "druid_cr": {{ .Release.Name }}
             "component": "router"
         topologyKey: "kubernetes.io/hostname"
{{- end}}
