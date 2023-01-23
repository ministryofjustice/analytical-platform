#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer/shared-library

VERSION=${VERSION:-"latest"}
GITHUB_REPOSITORY="99designs/aws-vault"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_NO_VERSION_PREFIX="${GITHUB_LATEST_TAG_NO_VERSION_PREFIX}"
else
  VERSION="${VERSION}"
fi

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/aws-vault-linux-${ARCHITECTURE} \
  --output /usr/local/bin/aws-vault
  
chmod +x /usr/local/bin/aws-vault
