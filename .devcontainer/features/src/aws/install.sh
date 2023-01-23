#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer/shared-library

VERSION=${VERSION:-"latest"}

if [[ "${VERSION}" == "latest" ]]; then
  ARTEFACT="awscli-exe-linux-$( uname -m ).zip"
else
  ARTEFACT="awscli-exe-linux-$( uname -m )-${VERSION}.zip"
fi

curl https://awscli.amazonaws.com/${ARTEFACT} --output ${ARTEFACT}

unzip ${ARTEFACT}

bash ./aws/install

rm --force --recursive aws ${ARTEFACT}
