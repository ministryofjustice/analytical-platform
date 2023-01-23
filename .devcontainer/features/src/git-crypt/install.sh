#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer/shared-library

DEBIAN_FRONTEND=noninteractive

apt update --yes

apt-get install --yes --no-install-recommends git-crypt

rm -rf /var/lib/apt/lists/*
