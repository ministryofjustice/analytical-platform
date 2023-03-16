#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${AWSVAULTVERSION:-"latest"}
GITHUB_REPOSITORY="99designs/aws-vault"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/aws-vault-linux-${ARCHITECTURE} \
  --output /usr/local/bin/aws-vault

chmod +x /usr/local/bin/aws-vault

mkdir --parents /home/vscode/.awsvault

chown --recursive vscode:vscode /home/vscode/.awsvault

### Config

mkdir --parents /home/vscode/.awsvault

chown --recursive vscode:vscode /home/vscode/.awsvault

echo "export AWS_VAULT_BACKEND=\"file\"" > /home/vscode/.dotfiles/aws-vault.sh
echo "export AWS_VAULT_FILE_PASSPHRASE=\"\"" >> /home/vscode/.dotfiles/aws-vault.sh
