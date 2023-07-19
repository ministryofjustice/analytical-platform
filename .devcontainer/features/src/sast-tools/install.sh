#!/usr/bin/env bash

if [[ "${INSTALLCHECKOV}" == "true" ]]; then
  bash $( dirname $0 )/install-checkov.sh
fi

if [[ "${INSTALLTRIVY}" == "true" ]]; then
  bash $( dirname $0 )/install-trivy.sh
fi
