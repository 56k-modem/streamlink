#!/bin/bash
docker exec -it streamlink /bin/bash -c "streamlink --version"
cd ~/streamlink
docker compose rm -s -f
docker image prune -a -f
docker buildx prune -f
docker build --pull --tag=streamlink --no-cache --progress=plain .
docker compose up -d
docker exec -it streamlink /bin/bash -c "streamlink --version"
