# Docker image and container for recording Twitch streams using Streamlink

[![Liberapay donations](https://img.shields.io/liberapay/patrons/56kmodem.svg?logo=liberapay)](https://liberapay.com/56kmodem/donate) ![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/56k-modem/streamlink/.github%2Fworkflows%2Fdocker-image.yml)

## Build

```bash
docker build --pull --tag=streamlink --no-cache .
```

## Start

```bash
docker compose up -d
```

## Update

```bash
./update.sh
```
