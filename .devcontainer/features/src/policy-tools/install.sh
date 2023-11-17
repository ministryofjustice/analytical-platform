#!/usr/bin/env bash

if [[ "${INSTALLOPA}" == "true" ]]; then
  bash $( dirname $0 )/install-opa.sh
fi

if [[ "${INSTALLCONFTEST}" == "true" ]]; then
  bash $( dirname $0 )/install-conftest.sh
fi

if [[ "${INSTALLGATOR}" == "true" ]]; then
  bash $( dirname $0 )/install-gator.sh
fi
