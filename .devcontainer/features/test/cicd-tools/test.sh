#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "act version" act --version

reportResults
