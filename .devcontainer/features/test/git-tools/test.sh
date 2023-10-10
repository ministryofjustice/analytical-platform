#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "gh version" gh version
check "git-crypt version" git-crypt --version
check "pre-commit version" pre-commit --version
check "detect-secrets version" detect-secrets --version
check "gitmoji version" gitmoji --version

reportResults
