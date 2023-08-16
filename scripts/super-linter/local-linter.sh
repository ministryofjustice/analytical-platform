#!/usr/bin/env bash

docker run --rm \
  --env RUN_LOCAL="true" \
  --env CREATE_LOG_FILE="true" \
  --env LOG_FILE="super-linter.log" \
  --env USE_FIND_ALGORITHM="true" \
  --env-file ".github/super-linter.env" \
  --volume "${PWD}":/tmp/lint \
  --workdir /tmp/lint \
  ghcr.io/super-linter/super-linter:slim-v5
