#!/usr/bin/env bash

if [[ "${INSTALLAWSCLI}" == "true" ]]; then
  bash $( dirname $0 )/install-aws-cli.sh
fi

if [[ "${INSTALLAWSVAULT}" == "true" ]]; then
  bash $( dirname $0 )/install-aws-vault.sh
fi

if [[ "${INSTALLAWSNUKE}" == "true" ]]; then
  bash $( dirname $0 )/install-aws-nuke.sh
fi
