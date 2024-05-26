#!/bin/bash
streamlink "--twitch-api-header=Authorization=OAuth $(cat oauth.txt)" twitch.tv/name best -o "/twitch/{time}.ts" --retry-streams 5

# ls
lscontent="ls -lh /twitch/ | awk '{print \$5, \$6, \$7, \$8, \$9}'"
curl -H ta:floppy_disk -H "t: streamlink just completed a recording!" -d "$(eval $lscontent)" ntfy.sh/topic

# length
lengthscript() {
for FILE in /twitch/*.ts; do
    filename=$(echo "$FILE" | sed 's/\/twitch\///g')
    duration=$(ffprobe -i "$FILE" -show_entries format=duration -v quiet -of csv="p=0" -sexagesimal | sed 's/.......$//')
    echo "$filename $duration"
done
}
curl -H ta:stopwatch -H "t: length listing" -d "$(lengthscript)" ntfy.sh/topic
