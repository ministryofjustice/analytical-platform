#!/usr/bin/env bash

if [[ "${INSTALLKUBECTL}" == "true" ]]; then
  bash $( dirname $0 )/install-kubectl.sh
fi

if [[ "${INSTALLHELM}" == "true" ]]; then
  bash $( dirname $0 )/install-helm.sh
fi

if [[ "${INSTALLFLUX}" == "true" ]]; then
  bash $( dirname $0 )/install-flux.sh
fi

if [[ "${INSTALLKUBENT}" == "true" ]]; then
  bash $( dirname $0 )/install-kubent.sh
fi
