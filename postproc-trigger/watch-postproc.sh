#!/bin/sh
# Runs inside the docker:cli container

set -eu

echo "[watch-postproc] Watching for recorder events..."

docker events \
  --filter 'event=start' \
  --filter 'event=die' \
  --format '{{.Action}} {{.Actor.Attributes.name}}' |
while read action cname; do
  case "$cname" in
    streamlink-twitch*|streamlink-kick*)
      case "$action" in
        start)
          echo "[watch-postproc] $(date '+%F %T') $cname started - monitoring logs..."
          docker logs --follow --timestamps "$cname" 2>&1 | grep "Opening stream" |
          while IFS= read -r line; do
            echo "[watch-postproc] [$cname] $line"
          done &
          ;;
        die)
          echo "[watch-postproc] $(date '+%F %T')  $cname ended - running vcsi"
          docker exec vcsi /usr/local/bin/vcsi-run.sh
          echo "[watch-postproc] $(date '+%F %T') vcsi finished"
          ;;
      esac
      ;;
  esac
done
