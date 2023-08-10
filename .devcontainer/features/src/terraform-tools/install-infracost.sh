#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${INFRACOSTVERSION:-"latest"}
GITHUB_REPOSITORY="infracost/infracost"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/infracost-linux-${ARCHITECTURE}.tar.gz \
    --output infracost-linux-${ARCHITECTURE}.tar.gz

tar -zxvf infracost-linux-${ARCHITECTURE}.tar.gz

mv infracost-linux-${ARCHITECTURE} /usr/local/bin/infracost

chmod +x /usr/local/bin/infracost

rm infracost-linux-${ARCHITECTURE}.tar.gz
