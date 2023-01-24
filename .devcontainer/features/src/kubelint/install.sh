#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer/shared-library

VERSION=${VERSION:-"latest"}
GITHUB_REPOSITORY="stackrox/kube-linter"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/kube-linter-linux \
  --output kube-linter-linux

mv kube-linter-linux /usr/local/bin/kubelint
  
chmod +x /usr/local/bin/kubelint
