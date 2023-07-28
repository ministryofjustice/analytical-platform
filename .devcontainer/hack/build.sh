#!/usr/bin/env bash

devcontainer build \
  --image-name "ghcr.io/ministryofjustice/data-platform-devcontainer:latest" \
  --platform "linux/arm64" \
  --push "false" \
  --workspace-folder . \
  --config .devcontainer/devcontainer-build.json
