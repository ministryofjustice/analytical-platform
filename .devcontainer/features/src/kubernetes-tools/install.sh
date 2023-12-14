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

if [[ "${INSTALLMOJCPCLI}" == "true" ]]; then
  bash $( dirname $0 )/install-moj-cp-cli.sh
fi

if [[ "${INSTALLK9S}" == "true" ]]; then
  bash $( dirname $0 )/install-k9s.sh
fi

if [[ "${INSTALLVELERO}" == "true" ]]; then
  bash $( dirname $0 )/install-velero.sh
fi

if [[ "${INSTALLHELMCT}" == "true" ]]; then
  bash $( dirname $0 )/install-helm-ct.sh
fi
