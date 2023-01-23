#!/usr/bin/env bash

TMPDIR=$( mktemp -d ${HOME}/.tmp-XXXXX )

FEATURE="${1}"

for platform in "amd64" "arm64" ; do
  docker buildx build --file .devcontainer/src/Dockerfile --platform linux/${platform} --tag devcontainer:${platform} .devcontainer/src 
  devcontainer features test --log-level debug --skip-scenarios --project-folder .devcontainer/features --features ${FEATURE} --base-image devcontainer:${platform}
done

rm -rf ${TMPDIR}
