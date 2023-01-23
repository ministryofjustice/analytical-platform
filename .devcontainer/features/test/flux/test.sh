#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "version" flux --version

reportResults
