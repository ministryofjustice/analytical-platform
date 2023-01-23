#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer/shared-library

VERSION=${VERSION:-"latest"}
GITHUB_REPOSITORY="doitintl/kube-no-trouble"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_NO_VERSION_PREFIX="${GITHUB_LATEST_TAG_NO_VERSION_PREFIX}"
else
  VERSION="${VERSION}"
fi

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/kubent-${VERSION}-linux-${ARCHITECTURE}.tar.gz \
  --output kubent-${KUBENT_VERSION}-linux-${ARCHITECTURE}.tar.gz

tar -zxvf kubent-${KUBENT_VERSION}-linux-${ARCHITECTURE}.tar.gz

mv kubent /usr/local/bin/kubent
  
chmod +x /usr/local/bin/kubent

rm kubent-${KUBENT_VERSION}-linux-${ARCHITECTURE}.tar.gz
