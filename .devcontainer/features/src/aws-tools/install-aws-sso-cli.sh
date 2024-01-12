#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${AWSSSOCLIVERSION:-"latest"}
GITHUB_REPOSITORY="synfinatic/aws-sso-cli"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/aws-sso-${VERSION_STRIP_V}-linux-${ARCHITECTURE} \
  --output /usr/local/bin/aws-sso

chmod +x /usr/local/bin/aws-sso

mkdir --parents /home/vscode/.aws-sso

cp  $( dirname $0 )/src/home/vscode/.aws-sso/config.yaml /home/vscode/.aws-sso/config.yaml

chown --recursive vscode:vscode /home/vscode/.aws-sso

### Config

echo "export AWS_SSO_FILE_PASSWORD=\"aws_sso_123456789\"" > /home/vscode/.dotfiles/aws-sso-cli.sh
