#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aws-cli version" aws --version
check "aws-vault version" aws-vault --version
check "aws-nuke version" aws-nuke version

reportResults
