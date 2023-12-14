#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${HELMCTVERSION:-"latest"}
GITHUB_REPOSITORY="helm/chart-testing"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/helm/chart-testing/releases/download/${VERSION}/chart-testing_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.tar.gz \
    --output chart-testing_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.tar.gz

tar -zxvf chart-testing_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.tar.gz

mv ct /usr/local/bin/ct

chmod +x /usr/local/bin/ct

mkdir --parents /home/vscode/.ct

mv etc/chart_schema.yaml /home/vscode/.ct/chart_schema.yaml

mv etc/lintconf.yaml /home/vscode/.ct/lintconf.yaml

rm --force --recursive chart-testing_${VERSION_STRIP_V}_linux_${ARCHITECTURE}.tar.gz LICENSE README.md
