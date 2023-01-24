#!/usr/bin/env bash

if [[ "${INSTALLTERRAFORM}" == "true" ]]; then
  bash $( dirname $0 )/install-terraform.sh
fi
