#!/usr/bin/env bash

if [[ "${INSTALLGITHUBCLI}" == "true" ]]; then
  bash $( dirname $0 )/install-gh.sh
fi

if [[ "${INSTALLGITCRYPT}" == "true" ]]; then
  bash $( dirname $0 )/install-git-crypt.sh
fi

if [[ "${INSTALLPRECOMMIT}" == "true" ]]; then
  bash $( dirname $0 )/install-pre-commit.sh
fi

if [[ "${INSTALLDETECTSECRETS}" == "true" ]]; then
  bash $( dirname $0 )/install-detect-secrets.sh
fi

if [[ "${INSTALLGITMOJI}" == "true" ]]; then
  bash $( dirname $0 )/install-gitmoji.sh
fi
