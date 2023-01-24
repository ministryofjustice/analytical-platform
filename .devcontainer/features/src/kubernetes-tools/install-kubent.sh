#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${KUBENTVERSION:-"latest"}
GITHUB_REPOSITORY="doitintl/kube-no-trouble"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/kubent-${VERSION}-linux-${ARCHITECTURE}.tar.gz \
  --output kubent-${KUBENT_VERSION}-linux-${ARCHITECTURE}.tar.gz

tar -zxvf kubent-${KUBENT_VERSION}-linux-${ARCHITECTURE}.tar.gz

mv kubent /usr/local/bin/kubent
  
chmod +x /usr/local/bin/kubent

rm kubent-${KUBENT_VERSION}-linux-${ARCHITECTURE}.tar.gz
