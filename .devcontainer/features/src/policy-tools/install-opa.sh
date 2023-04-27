#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${OPAVERSION:-"latest"}
GITHUB_REPOSITORY="open-policy-agent/opa"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/opa_linux_${ARCHITECTURE}_static \
  --output /usr/local/bin/opa

chmod +x /usr/local/bin/opa
