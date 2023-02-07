#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${VERSION:-"latest"}
GITHUB_REPOSITORY="cli/cli"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/cli/cli/releases/download/${VERSION}/gh_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.tar.gz \
  --output gh_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.tar.gz

tar -zxvf gh_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.tar.gz

mv gh_${VERSION_STRIP_V}_linux_${ARCHITECTURE}/bin/gh /usr/local/bin/gh

rm -rf gh_${VERSION_STRIP_V}_linux_${ARCHITECTURE}*

### Completion

gh completion -s zsh > /usr/local/share/zsh/site-functions/_gh

### Config

mkdir --parents /home/vscode/.config/gh

chown --recursive vscode:vscode /home/vscode/.config/gh
