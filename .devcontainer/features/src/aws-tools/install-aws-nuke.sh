#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${AWSNUKEVERSION:-"latest"}
GITHUB_REPOSITORY="rebuy-de/aws-nuke"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/aws-nuke-${VERSION}-linux-${ARCHITECTURE}.tar.gz \
  --output aws-nuke-${VERSION}-linux-${ARCHITECTURE}.tar.gz

tar -zxvf aws-nuke-${VERSION}-linux-${ARCHITECTURE}.tar.gz

mv aws-nuke-${VERSION}-linux-${ARCHITECTURE} /usr/local/bin/aws-nuke

rm -rf aws-nuke-${VERSION}-linux-${ARCHITECTURE}.tar.gz
