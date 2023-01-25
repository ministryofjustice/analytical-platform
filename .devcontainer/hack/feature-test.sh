#!/usr/bin/env bash

TMPDIR=$( mktemp -d ${HOME}/.tmp-XXXXX )

FEATURE="${1}"

docker build --file .devcontainer/features/test/Dockerfile --tag devcontainer .

devcontainer features test --log-level debug --skip-scenarios --project-folder .devcontainer/features --features ${FEATURE} --base-image devcontainer

rm -rf ${TMPDIR}
