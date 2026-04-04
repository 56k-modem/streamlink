#!/bin/bash
docker rm vcsi-manual 2>/dev/null || true
docker compose -f ~/docker/streamlink/docker-compose.yml run --name vcsi-manual vcsi --rescan
