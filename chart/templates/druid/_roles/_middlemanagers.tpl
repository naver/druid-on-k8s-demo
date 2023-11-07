{{/*
  Druid on K8S
  Copyright (c) 2023-present NAVER Corp.
  Apache-2.0
*/}}
{{- define "middlemanager" }}
nodeType: "middleManager"
druid.port: {{ .Values.druid.port }}
ports:
  - name: prom-metrics
    containerPort: {{ .Values.prometheus.port }}
nodeConfigMountPath: "/opt/druid/conf/druid/cluster/data/middleManager"
replicas: {{ .Values.middlemanagers.replicas }}
log4j.config: |-
  {{- include "log4j.config" (merge (dict "role" "middleManager") .) | indent 4 }}
resources:
  limits:
    cpu: {{ .Values.middlemanagers.resources.limits.cpu | quote }}
    memory: {{ .Values.middlemanagers.resources.limits.memory }}
    ephemeral-storage: {{ .Values.middlemanagers.resources.limits.ephemeralStorage }}
  requests:
    cpu: {{ .Values.middlemanagers.resources.requests.cpu | quote }}
    memory: {{ .Values.middlemanagers.resources.requests.memory }}
    ephemeral-storage: {{ .Values.middlemanagers.resources.requests.ephemeralStorage }}
#podDisruptionBudgetSpec:
#  maxUnavailable: 1
runtime.properties: |-
  druid.service=druid/middleManager
  druid.worker.capacity={{ .Values.middlemanagers.workerCapacity }}
  druid.server.http.numThreads={{ .Values.middlemanagers.http.numThreads }}
  druid.indexer.task.baseTaskDir=/druid/data/baseTaskDir

  # Processing threads and buffers on Peons
  druid.indexer.task.hadoopWorkingPath={{ .Values.middlemanagers.peon.taskHadoopWorkingPath }}
  druid.indexer.runner.javaOptsArray=[ \
        "-Xmx{{ .Values.middlemanagers.peon.jvmOptions.maxHeapSize}}", \
        "-XX:MaxDirectMemorySize={{ .Values.middlemanagers.peon.jvmOptions.maxDirectMemorySize }}", \
        "-Djava.io.tmpdir=/druid/data/tmp" \
  ]

  {{- if .Values.monitors.middlemanagers }}
  # monitoring
  druid.monitoring.monitors=[{{ printf "\"%s\"" (join "\",\"" (concat .Values.monitors.common .Values.monitors.middlemanagers)) }}]
  {{- end }}
terminationGracePeriodSeconds: 3600
lifecycle:
  # Purpose of preStop: prevent middleManager from dying while ingestion
  # Note: You should not only look at localhost tasks, but global tasks must be 0 to die.
  # Reason: The results of the terminated generate task are referenced in another merge task.
  preStop:
    exec:
      command:
      - /bin/bash
      - -c
      - |
        STDOUT=/dev/stdout
        STDERR=/dev/stderr

        FD1=/proc/1/fd/1
        FD2=/proc/1/fd/2

        # When testing in file, set to a value other than preStop
        output_mode="preStop"

        # When calling from preStop, you must redirect to "/proc/1/fd/1" to see the "k logs" result.
        if [ "$output_mode" == "preStop" ]
        then
          OUT=$FD1
          ERR=$FD2
        else
          OUT=$STDOUT
          ERR=$STDERR
        fi

        function log_msg()
        {
          echo "[preStop][$(date)] $@" >> $ERR
        }

        function disable_localhost()
        {
          curl -XPOST \
            --silent \
            'http://localhost:8088/druid/worker/v1/disable' >> $ERR 2>&1

          if [ $? -ne 0 ]
          then
            log_msg "[ERROR] disabling failed"

            exit 1
          fi

          log_msg "[INFO] This middleManager has been disabled, no more tasks will be assigned to this node"
        }

        function save_running_tasks_to_file_from_local()
        {
          disable_localhost

          curl \
            --silent \
            -o /tmp/runningTasks.txt \
            'http://localhost:8088/druid/worker/v1/tasks' 2>> $ERR

          if [ $? -ne 0 ]
          then
            log_msg "[ERROR] getting local running task has been failed"

            exit 1
          fi
        }

        function save_running_tasks_to_file_from_router()
        {
          local _http_code=$(curl \
            --silent \
            -w '%{http_code}' \
            -o /tmp/runningTasks.txt \
            'http://druid-{{ .Release.Name }}-routers/druid/indexer/v1/runningTasks' 2>> $ERR )

          local _exit_code=$?

          if [ $_exit_code != 0 ]
          then
            log_msg "[ERROR] exit_code was '$_exit_code'"

            return 1
          fi

          if [ $_http_code != "200" ]
          then
            log_msg "[ERROR] http_code was '$_http_code'"

            return 1
          fi

          return 0
        }

        function save_running_tasks_to_file()
        {
          local _succeeded="false"

          local tot_try=3

          for cnt in $(seq 1 3)
          do
            log_msg "[$cnt/$tot_try] trying to get global running tasks from router"

            if save_running_tasks_to_file_from_router
            then
              _succeeded="true"

              break
            fi

            log_msg "sleeping 5 sec..."

            sleep 5
          done

          if [ $_succeeded == "false" ]
          then
            # When router lookup fails, only local task termination is supported.
            log_msg "[ERROR] getting runningTasks from router has been failed, switching to localhost mode"

            save_running_tasks_to_file_from_local
          fi
        }

        function get_running_tasks_from_file()
        {
          cat /tmp/runningTasks.txt
        }

        function main()
        {
          while [ true ]
          do
            # Why curl results are written to a file
            #
            # - It is inconvenient to receive http_code and url execution results to stdout at once.
            # - Therefore, save the two separately as follows
            #   - stdout: save http_code
            #   - file: url execution result
            save_running_tasks_to_file

            local _running_tasks=$(get_running_tasks_from_file)

            log_msg "[INFO] _running_tasks='${_running_tasks}'"

            if [[ "$_running_tasks" != "[]" ]]
            then
              log_msg "[INFO] some tasks are running, sleep 10 secs..."

              sleep 10
            else
              break
            fi
          done

          log_msg "[INFO] no tasks running"

          log_msg "[Done]"
        }

        main
extra.jvm.options: |-
  -Xmx{{ .Values.middlemanagers.jvmOptions.maxHeapSize }}
  -Xms{{ .Values.middlemanagers.jvmOptions.minHeapSize }}
affinity:
  podAntiAffinity:
   preferredDuringSchedulingIgnoredDuringExecution:
     - weight: 100
       podAffinityTerm:
         labelSelector:
           matchLabels:
             "druid_cr": {{ .Release.Name }}
             "component": "middleManager"
         topologyKey: "kubernetes.io/hostname"
{{- end }}
