#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

DEBIAN_FRONTEND=noninteractive

apt update --yes

apt-get install --yes --no-install-recommends git-crypt

rm --force --recursive /var/lib/apt/lists/*
