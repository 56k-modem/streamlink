#!/usr/bin/env bash
set -euo pipefail

TS_FOLDER="${TS_FOLDER:-/input}"
JPG_FOLDER="${JPG_FOLDER:-/output}"
FONT_PATH="${FONT_PATH:-/usr/share/fonts/truetype/Misc-Fixed-7x13.ttf}"
SEASON_DIR="$TS_FOLDER/TV Shows/Wubby Streams/Season 01"

RESCAN=false
for arg in "$@"; do
    [[ "$arg" == "--rescan" ]] && RESCAN=true
done

echo "[vcsi] $(date '+%F %T')  pass started"

###############################################################################
# Step 0 – purge stale JPEGs
# A JPEG is "stale" when its video file has been modified *after* the JPEG.
###############################################################################
_purge_stale_sheets() {
    local dir="$1"
    shopt -s nullglob
    for vid_path in "$dir"/*.mp4; do
        base="$(basename "$vid_path")"
        jpg_path="$JPG_FOLDER/$base.jpg"
        if [ -f "$jpg_path" ] && [ "$vid_path" -nt "$jpg_path" ]; then
            echo "[vcsi] deleting stale sheet for $base.jpg (video newer)"
            rm -v "$jpg_path"
        fi
    done
}

_purge_stale_sheets "$TS_FOLDER"
$RESCAN && _purge_stale_sheets "$SEASON_DIR"

###############################################################################
# Step 1 – generate sheets; skip any JPEGs that still exist
###############################################################################
_generate_sheets() {
    local dir="$1"
    vcsi "$dir" --no-overwrite \
         -t -T sw -w 900 -g 3x5 \
         --background-color 000000 \
         --metadata-font "$FONT_PATH" \
         --metadata-font-color ffffff \
         --metadata-font-size 12 \
         --timestamp-font "$FONT_PATH" \
         --timestamp-format "{H}:{M}:{S}" \
         --ignore-errors \
         --exclude-extensions jpg \
         -o "$JPG_FOLDER"
}

_generate_sheets "$TS_FOLDER"
$RESCAN && _generate_sheets "$SEASON_DIR"

echo "[vcsi] $(date '+%F %T') for jellyfin pass started"

sleep 2

###############################################################################
# Step 1b – generate 16:9 poster sheets next to the .mp4 files
# Output: VOD_filename.mp4 -> VOD_filename.jpg (alongside the .mp4)
###############################################################################
_generate_posters() {
    local dir="$1"
    shopt -s nullglob
    for vid_path in "$dir"/*.mp4; do
        base="$(basename "$vid_path")"        # e.g. VOD_filename.mp4
        poster_path="$dir/${base%.mp4}.jpg"   # e.g. VOD_filename.jpg
        gen_path="$dir/$base.jpg"             # e.g. VOD_filename.mp4.jpg (vcsi default)

        # Delete stale poster if video is newer
        if [ -f "$poster_path" ] && [ "$vid_path" -nt "$poster_path" ]; then
            echo "[vcsi] deleting stale poster for ${base%.mp4}.jpg (video newer)"
            rm -v "$poster_path"
        fi

        # Skip if poster already exists and is not stale
        if [ -f "$poster_path" ]; then
            continue
        fi

        # Generate poster (minimal, 16:9, no metadata/timestamps)
        vcsi "$vid_path" --no-overwrite \
          -w 3840 -g 5x3 \
          --background-color 000000 \
          --metadata-position hidden \
          --ignore-errors \
          --exclude-extensions jpg \
          -o "$dir"

        # Rename from "VOD_filename.mp4.jpg" to "VOD_filename.jpg"
        if [ -f "$gen_path" ]; then
            mv -v "$gen_path" "$poster_path"
            # Pad to exact 3840x2160 (centered, black bars top/bottom if needed)
            ffmpeg -hide_banner -y -i "$poster_path" -frames:v 1 -update 1 \
              -vf "scale=3840:-1,pad=3840:2160:(ow-iw)/2:(oh-ih)/2:black" \
              -q:v 2 \
              "$poster_path.tmp.jpg"
            mv -v "$poster_path.tmp.jpg" "$poster_path"
        fi
    done
}

_generate_posters "$TS_FOLDER"
$RESCAN && _generate_posters "$SEASON_DIR"

###############################################################################
# Step 2 – prune orphaned JPEGs (videos deleted or moved)
###############################################################################
for jpg_path in "$JPG_FOLDER"/*.jpg; do
    base="${jpg_path##*/}"; base="${base%.jpg}"
    # Also keep sheets whose video was renamed and moved to Season 01
    season_match=( "$SEASON_DIR"/*"$base" )
    [[ -f "$TS_FOLDER/$base" ]] || [[ -f "${season_match[0]:-}" ]] || { rm -v "$jpg_path"; }
done

###############################################################################
# Step 2b – prune orphaned 16:9 posters in $TS_FOLDER
###############################################################################
shopt -s nullglob
for jpg_path in "$TS_FOLDER"/*.jpg; do
    base="$(basename "$jpg_path" .jpg)"
    # Also keep posters whose video was renamed and moved to Season 01
    season_match=( "$SEASON_DIR"/*"${base}.mp4" )
    [[ -f "$TS_FOLDER/$base.mp4" ]] || [[ -f "${season_match[0]:-}" ]] || { echo "[vcsi] removing orphaned poster: $jpg_path"; rm -v "$jpg_path"; }
done

###############################################################################
# Step 3 – rename and move completed VODs to "Season 01" with Jellyfin naming
# Skips any mp4 whose .recording sentinel file still exists (still being written)
###############################################################################
mkdir -p "$SEASON_DIR"

echo "[vcsi] $(date '+%F %T') moving completed VODs to Season 01..."

# Find highest S01Exx episode number already in Season 01
highest=0
for f in "$SEASON_DIR"/Wubby\ Streams\ -\ S01E*.mp4; do
    [ -f "$f" ] || continue
    num=$(basename "$f" | sed -n 's/.*S01E\([0-9][0-9]*\).*/\1/p')
    [ -z "$num" ] && continue
    num=$(( 10#$num ))
    [ "$num" -gt "$highest" ] && highest=$num
done

# Move each completed mp4 (and its .jpg poster) from the input root to Season 01,
# sorted by modification time so multiple new VODs are numbered chronologically
while IFS= read -r mp4; do
    [ -f "$mp4" ] || continue
    base=$(basename "$mp4" .mp4)
    # Skip if the recording sentinel still exists (stream still in progress)
    if [ -f "$TS_FOLDER/${base}.recording" ]; then
        echo "[vcsi] skipping ${base}.mp4 (recording still in progress)"
        continue
    fi
    highest=$((highest + 1))
    ep=$(printf "%02d" "$highest")
    new_name="Wubby Streams - S01E${ep} - ${base}"
    mv -- "$mp4" "$SEASON_DIR/${new_name}.mp4"
    echo "[vcsi] moved ${base}.mp4 -> ${new_name}.mp4"
    jpg="$TS_FOLDER/${base}.jpg"
    if [ -f "$jpg" ]; then
        mv -- "$jpg" "$SEASON_DIR/${new_name}.jpg"
        echo "[vcsi] moved ${base}.jpg -> ${new_name}.jpg"
    fi
    sheet="$JPG_FOLDER/${base}.mp4.jpg"
    if [ -f "$sheet" ]; then
        mv -- "$sheet" "$JPG_FOLDER/${new_name}.mp4.jpg"
        echo "[vcsi] renamed sheet ${base}.mp4.jpg -> ${new_name}.mp4.jpg"
    fi
done < <(find "$TS_FOLDER" -maxdepth 1 -name "*.mp4" -printf '%T@ %p\n' | sort -n | sed 's/^[^ ]* //')

echo "[vcsi] $(date '+%F %T') VOD move finished"

echo "[vcsi] $(date '+%F %T')  pass finished"
