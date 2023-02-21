#!/usr/bin/env bash

if [[ "${INSTALLACT}" == "true" ]]; then
  bash $( dirname $0 )/install-act.sh
fi
