#!/usr/bin/env bash

TMPDIR=$( mktemp -d ${HOME}/.tmp-XXXXX )

FEATURE="${1}"

docker build --file .devcontainer/src/Dockerfile --tag moj-devcontainer-test .devcontainer/src

devcontainer features test --skip-scenarios --project-folder .devcontainer/features --features ${FEATURE} --base-image moj-devcontainer-test

rm -rf ${TMPDIR}
