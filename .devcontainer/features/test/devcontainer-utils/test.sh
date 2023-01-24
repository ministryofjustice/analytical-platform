#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "file existence" stat /usr/local/bin/devcontainer-utils

reportResults
