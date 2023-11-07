{{/*
  Druid on K8S
  Copyright (c) 2023-present NAVER Corp.
  Apache-2.0
*/}}
{{- define "log4j.config" }}
<?xml version="1.0" encoding="UTF-8" ?>
<Configuration status="{{ .Values.common.log4j.logLevel }}">
<Appenders>
    <Console name="Console" target="SYSTEM_OUT">
        <PatternLayout pattern="%d{ISO8601} %p [%t] %c - %m%n"/>
    </Console>
</Appenders>
<Loggers>
    <Root level="info">
        <AppenderRef ref="Console"/>
    </Root>
</Loggers>
</Configuration>
{{- end }}
