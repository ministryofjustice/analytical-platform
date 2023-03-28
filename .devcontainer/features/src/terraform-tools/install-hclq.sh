#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${HCLQVERSION:-"latest"}
GITHUB_REPOSITORY="mattolenik/hclq"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/hclq-linux-amd64 \
    --output /usr/local/bin/hclq

chmod +x /usr/local/bin/hclq
