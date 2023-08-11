#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "checkov version" checkov --version
check "trivy version" trivy --version

reportResults
