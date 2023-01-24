#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer/shared-library

VERSION=${VERSION:-"latest"}
GITHUB_REPOSITORY="fluxcd/flux2"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/flux_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.tar.gz \
  --output flux_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.tar.gz

tar -zxvf flux_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.tar.gz

mv flux /usr/local/bin/flux
  
chmod +x /usr/local/bin/flux

rm flux_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.tar.gz

echo "source <(flux completion zsh)" > /home/vscode/.dotfiles/flux.sh
