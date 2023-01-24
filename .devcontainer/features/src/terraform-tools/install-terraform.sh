#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${VERSION:-"latest"}
GITHUB_REPOSITORY="hashicorp/terraform"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl https://releases.hashicorp.com/terraform/${VERSION_STRIP_V}/terraform_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.zip \
  --output terraform_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.zip

unzip -q terraform_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.zip

mv terraform /usr/local/bin/terraform

rm --force --recursive terraform_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.zip

### Completion

echo "complete -o nospace -C /usr/local/bin/terraform terraform" > /home/vscode/.dotfiles/terraform.sh
