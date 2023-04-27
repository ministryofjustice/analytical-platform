#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${CONFTESTVERSION:-"latest"}
GITHUB_REPOSITORY="open-policy-agent/conftest"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

if [[ "${ARCHITECTURE}" == "amd64" ]]; then
  ARCHITECTURE="x86_64"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/conftest_${VERSION_STRIP_V}_Linux_${ARCHITECTURE}.tar.gz \
  --output conftest_${VERSION_STRIP_V}_Linux_${ARCHITECTURE}.tar.gz

tar -zxvf conftest_${VERSION_STRIP_V}_Linux_${ARCHITECTURE}.tar.gz

mv conftest /usr/local/bin/conftest

chmod +x /usr/local/bin/conftest

# rm LICENSE README.md conftest_${VERSION_STRIP_V}_Linux_${ARCHITECTURE}.tar.gz
