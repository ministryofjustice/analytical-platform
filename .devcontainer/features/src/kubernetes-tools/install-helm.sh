#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${HELMVERSION:-"latest"}
GITHUB_REPOSITORY="helm/helm"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://get.helm.sh/helm-${VERSION}-linux-${ARCHITECTURE}.tar.gz \
    --output helm-${VERSION}-linux-${ARCHITECTURE}.tar.gz

tar -zxvf helm-${VERSION}-linux-${ARCHITECTURE}.tar.gz

mv linux-${ARCHITECTURE}/helm /usr/local/bin/helm

chmod +x /usr/local/bin/helm

rm --force --recursive linux-${ARCHITECTURE} helm-${VERSION}-linux-${ARCHITECTURE}.tar.gz

### Config

mkdir --parents /home/vscode/.config/helm

chown --recursive vscode:vscode /home/vscode/.config/helm

### Completion

echo "source <(helm completion zsh)" > /home/vscode/.dotfiles/helm.sh
