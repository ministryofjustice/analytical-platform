#!/usr/bin/env bash

if [[ "${INSTALLTERRAFORMSWITCHER}" == "true" ]]; then
  bash $( dirname $0 )/install-terraform-switcher.sh
fi

if [[ "${INSTALLTERRAFORMDOCS}" == "true" ]]; then
  bash $( dirname $0 )/install-terraform-docs.sh
fi
