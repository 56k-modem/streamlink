#!/bin/bash
lengthscript() {
    shopt -s nullglob
    cd /wubby
    while IFS= read -r FILE; do
        echo "$FILE" $(ffprobe -i "$FILE" -show_entries format=duration -v quiet -of csv="p=0" -sexagesimal | sed 's/.......$//')
    done < <(ls -tr *.mp4 2>/dev/null)
}
lengthscript > /tmp/vodsdata.tmp
curl \
  -H "Authorization: Bearer ${NTFY_TOKEN:?NTFY_TOKEN env var required}" \
  -H "t: streamlink ntfy test" \
  -H ta:vhs \
  -H "Click: ${NTFY_CLICK_URL:?NTFY_CLICK_URL env var required}" \
  -d "$(cat /tmp/vodsdata.tmp)" \
  "${NTFY_URL:?NTFY_URL env var required}"
rm /tmp/vodsdata.tmp
