#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${VERSION:-"latest"}
GITHUB_REPOSITORY="ministryofjustice/cloud-platform-cli"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/cloud-platform-cli_${VERSION}_linux_${ARCHITECTURE}.tar.gz \
  --output cloud-platform-cli_${VERSION}_linux_${ARCHITECTURE}.tar.gz

tar -zxvf cloud-platform-cli_${VERSION}_linux_${ARCHITECTURE}.tar.gz

mv cloud-platform /usr/local/bin/cloud-platform
  
chmod +x /usr/local/bin/cloud-platform

mv completions/cloud-platform.zsh /usr/local/share/zsh/site-functions/_cloud-platform

chown root:root /usr/local/share/zsh/site-functions/_cloud-platform

rm --recursive --force LICENSE README.md completions cloud-platform-cli_${VERSION}_linux_${ARCHITECTURE}.tar.gz
