{{/*
  Druid on K8S
  Copyright (c) 2023-present NAVER Corp.
  Apache-2.0
*/}}
{{- define "historical" }}
nodeType: "historical"
druid.port: {{ .Values.druid.port }}
ports:
  - name: prometheus
    containerPort: {{ .Values.prometheus.port }}
nodeConfigMountPath: "/opt/druid/conf/druid/cluster/data/historical"
replicas: {{ .Values.historicals.replicas }}
log4j.config: |-
  {{- include "log4j.config" (merge (dict "role" "historical") .) | indent 4 }}
resources:
  limits:
    cpu: {{ .Values.historicals.resources.limits.cpu | quote }}
    memory: {{ .Values.historicals.resources.limits.memory }}
    ephemeral-storage: {{ .Values.historicals.resources.limits.ephemeralStorage }}
  requests:
    cpu: {{ .Values.historicals.resources.requests.cpu | quote }}
    memory: {{ .Values.historicals.resources.requests.memory }}
    ephemeral-storage: {{ .Values.historicals.resources.requests.ephemeralStorage }}
runtime.properties: |
  druid.service=druid/historical
  druid.server.http.numThreads={{ .Values.historicals.http.numThreads }}

  # Segment storage
  druid.segmentCache.locations=[{\"path\":\"{{ .Values.historicals.segmentCache.path }}\",\"maxSize\":\"{{ .Values.historicals.segmentCache.volumeSize }}\"}]

  # Settings to shorten the time it takes to load segment data into memory when restarting a historical pod.
  druid.segmentCache.numBootstrapThreads={{ .Values.historicals.segmentCache.numBootstrapThreads }}

  druid.historical.cache.useCache=true
  druid.historical.cache.populateCache=true

  {{- if .Values.monitors.historicals }}
  # monitoring
  druid.monitoring.monitors=[{{ printf "\"%s\"" (join "\",\"" (concat .Values.monitors.common .Values.monitors.historicals)) }}]
  {{- end }}
extra.jvm.options: |-
  -Xmx{{ .Values.historicals.jvmOptions.maxHeapSize }}
  -Xms{{ .Values.historicals.jvmOptions.minHeapSize }}
  -XX:MaxDirectMemorySize={{ .Values.historicals.jvmOptions.maxDirectMemorySize }}
affinity:
  podAntiAffinity:
   preferredDuringSchedulingIgnoredDuringExecution:
     - weight: 100
       podAffinityTerm:
         labelSelector:
           matchLabels:
             "druid_cr": {{ .Release.Name }}
             "component": "historical"
         topologyKey: "kubernetes.io/hostname"
#volumeClaimTemplates:
#  - metadata:
#      name: segment-volume-pvc
#    spec:
#      accessModes:
#        - "ReadWriteOnce"
#      storageClassName: "rbd-hdd"
#      resources:
#        requests:
#          storage: {{ .Values.historicals.segmentCache.volumeSize }}
#volumeMounts:
#  - mountPath: {{ .Values.historicals.segmentCache.path }}
#    name: segment-volume-pvc
{{- end }}
