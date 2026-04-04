#!/bin/bash
set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-/test}"
OAUTH="${TWITCH_OAUTH:?TWITCH_OAUTH env var required}"

read -rp "Twitch channel: " TWITCH_CHANNEL
read -rp "Kick channel:   " KICK_CHANNEL

UUID="$(cat /proc/sys/kernel/random/uuid | cut -c1-8)"
TWITCH_OUT="$OUTPUT_DIR/test-twitch-${TWITCH_CHANNEL}-${UUID}.mp4"
KICK_OUT="$OUTPUT_DIR/test-kick-${KICK_CHANNEL}-${UUID}.mp4"

echo "*** Starting test recordings for 60 seconds"
echo "    Twitch: twitch.tv/${TWITCH_CHANNEL} -> $(basename "$TWITCH_OUT")"
echo "    Kick:   kick.com/${KICK_CHANNEL} -> $(basename "$KICK_OUT")"

streamlink --stdout "--twitch-api-header=Authorization=OAuth ${OAUTH}" \
  "twitch.tv/${TWITCH_CHANNEL}" best | ffmpeg -hide_banner -nostats -t 60 -i pipe:0 -c copy -map 0:v -map 0:a -movflags +faststart "$TWITCH_OUT" &
TWITCH_PID=$!

streamlink --stdout "https://kick.com/${KICK_CHANNEL}" best | ffmpeg -hide_banner -nostats -t 60 -i pipe:0 -c copy -map 0:v -map 0:a -movflags +faststart "$KICK_OUT" &
KICK_PID=$!

echo "*** Stopping recordings"
wait "$TWITCH_PID" 2>/dev/null || true
wait "$KICK_PID"   2>/dev/null || true

echo "*** Running integrity checks"

check() {
    local file="$1" label="$2"
    echo ""
    echo "--- ${label}: $(basename "$file")"
    if [[ ! -f "$file" ]]; then
        echo "FAIL: file not found"
        return
    fi
    if [[ ! -s "$file" ]]; then
        echo "FAIL: file is empty"
        return
    fi
    ffprobe -v error \
        -show_entries format=duration,size,bit_rate \
        -show_entries stream=codec_type,codec_name,width,height \
        -of default=noprint_wrappers=1 \
        "$file" && echo && echo "*** PASS ***" && echo || echo "FAIL: ffprobe error"
    ffprobe -i "$file"
}

check "$TWITCH_OUT" "Twitch" || true
check "$KICK_OUT"   "Kick" || true

echo ""
echo "*** Cleaning up test files"
rm -fv "$OUTPUT_DIR"/test-*.mp4

echo "*** Test complete"
