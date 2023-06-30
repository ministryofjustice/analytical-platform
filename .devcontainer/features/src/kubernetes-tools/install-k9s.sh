#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${K9SVERSION:-"latest"}
GITHUB_REPOSITORY="derailed/k9s"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/k9s_Linux_${ARCHITECTURE}.tar.gz \
  --output k9s_Linux_${ARCHITECTURE}.tar.gz

tar -zxvf k9s_Linux_${ARCHITECTURE}.tar.gz

mv k9s /usr/local/bin/k9s

chmod +x /usr/local/bin/k9s

rm k9s_Linux_${ARCHITECTURE}.tar.gz LICENSE README.md
