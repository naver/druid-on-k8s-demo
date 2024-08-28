#!/bin/bash
#  Druid on K8S
#  Copyright (c) 2023-present NAVER Corp.
#  CC BY-SA 4.0

# Simply rotate files with a bash script

if [ $# -eq 0 ]
then
  echo "Usage) $0 log-file-path-1 [log-file-path-2 ...]"
  echo ""
  echo "ex) $0 /var/log/nginx/access.log /var/log/nginx/error.log"

  exit 1
fi

NUM_BACKUP_FILES=3

# 86400 secs => 1 day
SLEEP_IN_SEC=86400

# Bash script reference: https://stackoverflow.com/a/43309848/2930152 under CC BY-SA 4.0
function rotate_file()
{
  local _log_file_name=$1

  for cnt in $(seq $((NUM_BACKUP_FILES-1)) -1 1)
  do
    src=$_log_file_name.$cnt
    [ -e $src ] && /bin/mv -vf $src $_log_file_name.$((cnt+1))

  done

  [ -e $_log_file_name ] && /bin/mv -v $_log_file_name $_log_file_name.1
}

# reload to write logs to newly created file
function reload_nginx()
{
  local _nginx_pid="/run/nginx.pid"

  if [ -e $_nginx_pid ]
  then
    kill -USR1 $(<$_nginx_pid)
  fi
}

function rotate_files()
{
  for file in $@
  do
    rotate_file $file
  done
}

function main()
{
  while [ true ]
  do
    # Run once a day based on the execution time point.
    sleep $SLEEP_IN_SEC

    echo "====== log rotate started $(date) ========"
    rotate_files "$@"

    reload_nginx
    echo "[Done]"
  done
}

main "$@"
