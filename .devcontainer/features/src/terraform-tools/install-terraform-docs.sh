#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${TERRAFORMDOCSVERSION:-"latest"}
GITHUB_REPOSITORY="terraform-docs/terraform-docs"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/terraform-docs-${VERSION}-linux-${ARCHITECTURE}.tar.gz \
  --output terraform-docs-${VERSION}-linux-${ARCHITECTURE}.tar.gz

tar -zxvf terraform-docs-${VERSION}-linux-${ARCHITECTURE}.tar.gz

mv terraform-docs /usr/local/bin/terraform-docs
  
chmod +x /usr/local/bin/terraform-docs

rm LICENSE README.md terraform-docs-${VERSION}-linux-${ARCHITECTURE}.tar.gz
