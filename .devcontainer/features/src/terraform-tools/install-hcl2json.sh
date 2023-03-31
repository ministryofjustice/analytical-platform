#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${HCL2JSONVERSION:-"latest"}
GITHUB_REPOSITORY="tmccombs/hcl2json"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/hcl2json_linux_${ARCHITECTURE} \
    --output /usr/local/bin/hcl2json

chmod +x /usr/local/bin/hcl2json
