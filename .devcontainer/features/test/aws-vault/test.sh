#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "version" aws-vault --version

reportResults