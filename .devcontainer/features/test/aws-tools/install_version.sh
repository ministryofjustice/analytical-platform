#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aws-cli version" aws --version | grep "aws-cli/2.9.21"

reportResults
