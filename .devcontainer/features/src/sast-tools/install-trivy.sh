#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${TRIVYVERSION:-"latest"}
GITHUB_REPOSITORY="aquasecurity/trivy"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

if [[ "${ARCHITECTURE}" == "amd64" ]]; then
  ARCHITECTURE="64bit"
elif [[ "${ARCHITECTURE}" == "arm64" ]]; then
  ARCHITECTURE="ARM64"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/trivy_${VERSION_STRIP_V}_Linux-${ARCHITECTURE}.tar.gz \
  --output trivy_${VERSION_STRIP_V}_Linux-${ARCHITECTURE}.tar.gz

tar -zxvf trivy_${VERSION_STRIP_V}_Linux-${ARCHITECTURE}.tar.gz

mv trivy /usr/local/bin/trivy

chmod +x /usr/local/bin/trivy

rm -rf LICENSE README.md contrib trivy_${VERSION_STRIP_V}_Linux-${ARCHITECTURE}.tar.gz
