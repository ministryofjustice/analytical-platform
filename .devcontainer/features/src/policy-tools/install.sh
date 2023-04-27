#!/usr/bin/env bash

if [[ "${INSTALLOPA}" == "true" ]]; then
  bash $( dirname $0 )/install-opa.sh
fi
