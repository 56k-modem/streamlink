# Repository Guidelines

## Project Structure & Module Organization
This repository is a small Docker-first shell project. Top-level files define runtime behavior: `docker-compose.yml` wires services together, `Dockerfile` builds the recorder image, and `streamlinkcmd-*.sh` contains recorder entrypoints for Twitch, Kick, and local testing. Operational helpers live in `manual-*.sh` and `test.sh`. The `caddy/` directory contains the contact-sheet web image, `postproc-trigger/` contains the Docker event watcher image, and `vcsi/` contains the post-processing image, font asset, and `vcsi-run.sh` pipeline that generates sheets, posters, and Jellyfin-ready episode names.

## Build, Test, and Development Commands
Use Docker Compose for nearly all development work.

- `docker compose up -d`: start the recorder, web, and watcher services.
- `docker compose logs -f streamlink-twitch`: follow a single recorder while debugging.
- `./test.sh`: run the interactive `streamlink-test` container and verify 60-second sample captures.
- `./manual-vcsi.sh`: force a post-processing pass with `--rescan`.
- `docker build -t streamlink .`: build the recorder image locally.
- `docker build -t contact-sheets ./caddy`: build the contact-sheet web image locally.
- `docker build -t postproc-trigger ./postproc-trigger`: build the Docker event watcher image locally.
- `docker build -t vcsi ./vcsi`: build the post-processing image locally.

## Coding Style & Naming Conventions
Scripts use Bash or POSIX `sh` with simple, readable pipelines. Match the existing style: `#!/bin/bash` or `#!/bin/sh`, 2-space indentation in wrapped command blocks, uppercase environment variables (`TWITCH_OAUTH`, `CONTACT_SHEETS_DIR`), and lowercase hyphenated filenames such as `streamlinkcmd-twitch.sh`. Prefer `set -euo pipefail` for new Bash scripts unless the file already follows a different pattern. Keep log messages short and grep-friendly.

## Testing Guidelines
There is no formal unit-test suite. Validate changes by running `./test.sh`, then inspect `docker compose logs` and generated files under the mounted VOD and contact-sheet directories. When editing `vcsi/vcsi-run.sh`, verify both normal runs and `--rescan` behavior. Preserve naming rules like `Wubby Streams - S01E## - <source-id>.mp4`.

## Commit & Pull Request Guidelines
Recent commits use short imperative subjects, for example `Fix image published path` and `Remove unused services`. Keep commit titles brief, capitalized, and action-oriented. Pull requests should describe the operational impact, list any required `.env` or volume changes, and include relevant log snippets or screenshots when changing contact-sheet or Jellyfin-visible output.

## Configuration & Operations
Do not commit real tokens or host paths. Copy `.env.example` to `.env`, keep secrets local, and document any new environment variables in both the example file and `README.md`.
