#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "kubectl version" kubectl version --client=true --output yaml
check "helm version" helm version
check "flux version" flux --version
check "kubent version" kubent --version
check "cloud-platform version" cloud-platform version

reportResults
