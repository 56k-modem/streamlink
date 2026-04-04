#!/bin/bash
echo "*** Container starting"
RID=$(cat /proc/sys/kernel/random/uuid)
streamlink --retry-streams 5 --stdout https://kick.com/paymoneywubby best \
  2> >(
    while IFS= read -r line; do
      printf '%s\n' "$line" >&2
      if [[ "$line" == *"Opening stream"* ]]; then
        touch "/wubby/kick-${RID}.recording"
        curl -fsS -m 10 --retry 5 "https://hc-ping.com/${HC_UUID:?HC_UUID env var required}/start?rid=$RID"
        curl -fsS -m 10 --retry 5 "${HC_LOCAL_PING_URL:?HC_LOCAL_PING_URL env var required}/start?rid=$RID"
      fi
    done
  ) \
  | ffmpeg -hide_banner -nostats -i pipe:0 -c copy -map 0:v -map 0:a -movflags +faststart "/wubby/kick-${RID}.mp4"
wait
rm -f "/wubby/kick-${RID}.recording"
lengthscript() {
    shopt -s nullglob
    cd /wubby
    while IFS= read -r FILE; do
        echo "$FILE" $(ffprobe -i "$FILE" -show_entries format=duration -v quiet -of csv="p=0" -sexagesimal | sed 's/.......$//')
    done < <(ls -tr kick*.mp4 2>/dev/null)
}
lengthscript > /tmp/vodsdata.tmp
vodsdata=$(cat /tmp/vodsdata.tmp)
for url in \
  "https://hc-ping.com/${HC_UUID}?rid=$RID" \
  "${HC_LOCAL_PING_URL}?rid=$RID"; do
  curl -fsS -m 10 --retry 5 --data-raw "$vodsdata" "$url"
done
rm /tmp/vodsdata.tmp
mv "/wubby/kick-${RID}.mp4" "/wubby/kick-$(echo "$RID" | cut -c1-8).mp4"
