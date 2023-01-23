#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer/shared-library

VERSION=${VERSION:-"latest"}

if [[ "${VERSION}" == "latest" ]]; then
  VERSION=$( curl --location --silent https://dl.k8s.io/release/stable.txt )
fi

curl --location https://dl.k8s.io/release/${VERSION}/bin/linux/${ARCHITECTURE}/kubectl --output /usr/local/bin/kubectl
  chmod +x /usr/local/bin/kubectl