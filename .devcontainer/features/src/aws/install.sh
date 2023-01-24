#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer/shared-library

VERSION=${VERSION:-"latest"}
AWS_IAM_EMAIL="${AWSIAMEMAIL}"

if [[ "${VERSION}" == "latest" ]]; then
  ARTEFACT="awscli-exe-linux-$( uname -m ).zip"
else
  ARTEFACT="awscli-exe-linux-$( uname -m )-${VERSION}.zip"
fi

# Install

curl https://awscli.amazonaws.com/${ARTEFACT} --output ${ARTEFACT}

unzip ${ARTEFACT}

bash ./aws/install

rm --force --recursive aws ${ARTEFACT}

# Completion

echo "complete -C '/usr/local/bin/aws_completer' aws" > /home/vscode/.dotfiles/aws.sh

# Config

mkdir --parents /home/vscode/.aws

cp  $( dirname $0 )/config  /home/vscode/.aws/config

sed -i "s|AWS_IAM_EMAIL|${AWS_IAM_EMAIL}|g" /home/vscode/.aws/config

chown --recursive vscode:vscode /home/vscode/.aws
