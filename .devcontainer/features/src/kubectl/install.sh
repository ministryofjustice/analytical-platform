#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer/shared-library

VERSION=${VERSION:-"latest"}

if [[ "${VERSION}" == "latest" ]]; then
  VERSION=$( curl --location --silent https://dl.k8s.io/release/stable.txt )
fi

# Install

curl --location https://dl.k8s.io/release/${VERSION}/bin/linux/${ARCHITECTURE}/kubectl --output /usr/local/bin/kubectl
  chmod +x /usr/local/bin/kubectl

# Completion

echo "source <(kubectl completion zsh)" > /home/vscode/.dotfiles/kubectl.sh

# Config

mkdir --parents /home/vscode/.kube

cp  $( dirname $0 )/config  /home/vscode/.kube/config

chown --recursive vscode:vscode /home/vscode/.kube
