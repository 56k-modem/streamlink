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
          docker rm vcsi-runner 2>/dev/null || true
          docker run \
            --name vcsi-runner \
            --user "1000:1000" \
            -v "${VOD_DIR:?VOD_DIR env var required}:/input" \
            -v "${CONTACT_SHEETS_DIR:?CONTACT_SHEETS_DIR env var required}:/output" \
            ghcr.io/56k-modem/vcsi:latest
          echo "[watch-postproc] $(date '+%F %T') vcsi finished"
          ;;
      esac
      ;;
  esac
done
