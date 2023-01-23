#!/usr/bin/env bash

TMPDIR=$( mktemp -d ${HOME}/.tmp-XXXXX )

FEATURE="${1}"

docker build --file .devcontainer/src/Dockerfile --tag devcontainer .devcontainer/src

devcontainer features test --skip-scenarios --project-folder .devcontainer/features --features ${FEATURE} --base-image devcontainer

rm -rf ${TMPDIR}
