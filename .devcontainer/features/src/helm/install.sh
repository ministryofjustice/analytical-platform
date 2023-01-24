#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer/shared-library

VERSION=${VERSION:-"latest"}
GITHUB_REPOSITORY="helm/helm"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/kube-linter-linux \
  --output kube-linter-linux

###

curl --location https://get.helm.sh/helm-${VERSION}-linux-${ARCHITECTURE}.tar.gz \
    --output helm-${VERSION}-linux-${ARCHITECTURE}.tar.gz

tar -zxvf helm-${VERSION}-linux-${ARCHITECTURE}.tar.gz

mv linux-${ARCHITECTURE}/helm /usr/local/bin/helm

chmod +x /usr/local/bin/helm

rm -rf linux-${ARCHITECTURE} helm-${VERSION}-linux-${ARCHITECTURE}.tar.gz
