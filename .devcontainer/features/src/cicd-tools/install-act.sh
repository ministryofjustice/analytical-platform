#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${ACTVERSION:-"latest"}
GITHUB_REPOSITORY="nektos/act"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/act_Linux_${ARCHITECTURE}.tar.gz \
    --output act_Linux_${ARCHITECTURE}.tar.gz

tar -zxvf act_Linux_${ARCHITECTURE}.tar.gz

mv act /usr/local/bin/act

rm -rf LICENSE README.md act_Linux_${ARCHITECTURE}.tar.gz
