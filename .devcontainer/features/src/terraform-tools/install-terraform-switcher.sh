#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${VERSION:-"latest"}
GITHUB_REPOSITORY="warrensbox/terraform-switcher"

TERRAFORM_VERSION=${TERRAFORMVERSION:-"latest"}
TERRAFORM_GITHUB_REPOSITORY="hashicorp/terraform"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

if [ "${TERRAFORM_VERSION}" == "latest" ]; then
  get_github_latest_tag ${TERRAFORM_GITHUB_REPOSITORY}
  TERRAFORM_VERSION="${GITHUB_LATEST_TAG}"
  TERRAFORM_VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  TERRAFORM_VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/terraform-switcher_${VERSION}_linux_${ARCHITECTURE}.tar.gz \
  --output terraform-switcher_${VERSION}_linux_${ARCHITECTURE}.tar.gz

tar -zxvf terraform-switcher_${VERSION}_linux_${ARCHITECTURE}.tar.gz

mv tfswitch /usr/local/bin/tfswitch

chmod +x /usr/local/bin/tfswitch

rm --force --recursive CHANGELOG.md LICENSE README.md terraform-switcher_${VERSION}_linux_${ARCHITECTURE}.tar.gz

### Config

mkdir --parents /home/vscode/terraform-bin

chown --recursive vscode:vscode /home/vscode/terraform-bin

cp $( dirname $0 )/src/home/vscode/.tfswitch.toml /home/vscode/.tfswitch.toml

chown vscode:vscode /home/vscode/.tfswitch.toml

su - vscode --command "tfswitch ${TERRAFORM_VERSION_STRIP_V}"

echo "export PATH=\"\${PATH}:\${HOME}/terraform-bin\"" > /home/vscode/.dotfiles/terraform.sh

### Completion

echo "complete -o nospace -C \${HOME}/terraform-bin/terraform terraform" >> /home/vscode/.dotfiles/terraform.sh
