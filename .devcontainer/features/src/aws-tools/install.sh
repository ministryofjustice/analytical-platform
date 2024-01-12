#!/usr/bin/env bash

if [[ "${INSTALLAWSCLI}" == "true" ]]; then
  bash $( dirname $0 )/install-aws-cli.sh
fi

if [[ "${INSTALLAWSSSOCLI}" == "true" ]]; then
  bash $( dirname $0 )/install-aws-sso-cli.sh
fi

if [[ "${INSTALLAWSNUKE}" == "true" ]]; then
  bash $( dirname $0 )/install-aws-nuke.sh
fi
