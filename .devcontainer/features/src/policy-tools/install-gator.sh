#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${GATORVERSION:-"latest"}
GITHUB_REPOSITORY="open-policy-agent/gatekeeper"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/gator-${VERSION}-linux-${ARCHITECTURE}.tar.gz \
  --output gator-${VERSION}-linux-${ARCHITECTURE}.tar.gz

tar -zxvf gator-${VERSION}-linux-${ARCHITECTURE}.tar.gz

mv gator /usr/local/bin/gator

chmod +x /usr/local/bin/gator

rm gator-${VERSION}-linux-${ARCHITECTURE}.tar.gz
