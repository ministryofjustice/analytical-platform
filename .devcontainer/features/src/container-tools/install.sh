#!/usr/bin/env bash

if [[ "${INSTALLCOSIGN}" == "true" ]]; then
  bash $( dirname $0 )/install-cosign.sh
fi
