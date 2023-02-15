#!/usr/bin/env bash

if [[ "${INSTALLPULUMI}" == "true" ]]; then
  bash $( dirname $0 )/install-pulumi.sh
fi
