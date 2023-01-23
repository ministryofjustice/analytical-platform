#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "version" kubectl version --client=true --output yaml

reportResults
