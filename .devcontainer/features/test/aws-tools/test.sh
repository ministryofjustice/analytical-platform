#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aws-cli version" aws --version
check "aws-sso version" aws-sso version
check "aws-nuke version" aws-nuke version

reportResults
