#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${VELEROVERSION:-"latest"}
GITHUB_REPOSITORY="vmware-tanzu/velero"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/velero-${VERSION}-linux-${ARCHITECTURE}.tar.gz \
  --output velero-${VERSION}-linux-${ARCHITECTURE}.tar.gz

tar -zxvf velero-${VERSION}-linux-${ARCHITECTURE}.tar.gz

mv velero-${VERSION}-linux-${ARCHITECTURE}/velero /usr/local/bin/velero

chmod +x /usr/local/bin/velero

rm -rf velero-${VERSION}-linux-${ARCHITECTURE} velero-${VERSION}-linux-${ARCHITECTURE}.tar.gz
