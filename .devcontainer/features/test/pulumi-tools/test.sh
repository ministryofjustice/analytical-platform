#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "pulumi version" pulumi version

reportResults
