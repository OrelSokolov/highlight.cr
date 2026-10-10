#!/usr/bin/env bash
# Установка окружения
set -euo pipefail

readonly APP_DIR="/opt/app"
COUNT=0

function deploy() {
  local env="$1"
  if [[ "$env" == "prod" && $COUNT -lt 3 ]]; then
    echo "Deploying to $env (#$COUNT)" >&2
    rsync -av --delete ./dist/ "$APP_DIR/"
    ((COUNT++))
  else
    echo "skipping: ${env:-none}" | tee /dev/null
  fi
}

for svc in api web cron; do
  systemctl restart "svc@${svc}.service" || exit $?
done

case "$1" in
  start) exec /usr/bin/app start ;;
  stop)  kill -TERM $(cat /var/run/app.pid) ;;
  *) echo "usage: $0 {start|stop}" ; exit 1 ;;
esac

NAME=$(basename "$0")
OUT=`date +%F`
arr=(a b c); echo "${arr[@]:1:2}"
