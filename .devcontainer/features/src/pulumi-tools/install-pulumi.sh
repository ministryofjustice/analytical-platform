#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${PULUMIVERSION:-"latest"}
GITHUB_REPOSITORY="pulumi/pulumi"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

### Install

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/pulumi-${VERSION}-linux-${ARCHITECTURE}.tar.gz \
  --output pulumi-${VERSION}-linux-${ARCHITECTURE}.tar.gz

tar -zxvf pulumi-${VERSION}-linux-${ARCHITECTURE}.tar.gz

mv pulumi/* /usr/local/bin/

rm -rf pulumi pulumi-${VERSION}-linux-${ARCHITECTURE}.tar.gz

### Completion

pulumi gen-completion zsh > /usr/local/share/zsh/site-functions/_pulumi
