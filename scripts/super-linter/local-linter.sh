#!/usr/bin/env bash

docker run --rm \
  --env RUN_LOCAL="true" \
  --env USE_FIND_ALGORITHM="true" \
  --env-file ".github/super-linter.env" \
  --volume "${PWD}":/tmp/lint \
  --workdir /tmp/lint \
  ghcr.io/github/super-linter:v5.0.0
