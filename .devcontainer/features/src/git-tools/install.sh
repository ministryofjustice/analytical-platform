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
