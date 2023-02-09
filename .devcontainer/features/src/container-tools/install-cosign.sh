#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${COSIGNVERSION:-"latest"}
GITHUB_REPOSITORY="sigstore/cosign"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/cosign-linux-${ARCHITECTURE} \
    --output /usr/local/bin/cosign

chmod +x /usr/local/bin/cosign
