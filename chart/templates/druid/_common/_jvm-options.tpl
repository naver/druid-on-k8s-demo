{{/*
  Druid on K8S
  Copyright (c) 2023-present NAVER Corp.
  Apache-2.0
*/}}
{{- define "jvm.options" }}
-server
-Duser.timezone=UTC
-Dfile.encoding=UTF-8
{{- if .Values.common.log4j.debugEnabled }}
-Dlog4j.debug
{{- end }}
-Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager
-Djava.io.tmpdir=/druid/data
{{- end }}
