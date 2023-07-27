#!/usr/bin/env bash

# Need coder binary first (curl -L https://coder.com/install.sh | sh)

export CODER_URL="https://coder.data-platform.moj.woffenden.dev"
export CODER_SESSION_TOKEN="REPLACE_ME_BUT_DONT_COMMIT_IT"

export CODER_TEMPLATE_NAME="${1}"
export CODER_TEMPLATE_DIR="terraform/aws/analytical-platform-development/firebreak-coder/src/coder/templates/${CODER_TEMPLATE_NAME}"
export CODER_TEMPLATE_VERSION=$(date +"%Y%m%dT%H%M%S")
export CODER_TEMPLATE_MESSAGE="A new version!"

if [[ ! -d "${CODER_TEMPLATE_DIR}" ]]; then
  echo "(!) template directory doesn't exit"
  exit 1
fi

if [[ $(coder templates list --output json | jq -r --arg TEMPLATE_NAME "${CODER_TEMPLATE_NAME}" '.[] | select(.Template.name == $TEMPLATE_NAME) | .Template.name') == "${CODER_TEMPLATE_NAME}" ]]; then
  echo "(*) Template found, updating"

  coder templates push "${CODER_TEMPLATE_NAME}" --directory="${CODER_TEMPLATE_DIR}" --yes --name="${CODER_TEMPLATE_VERSION}" --message=""${CODER_TEMPLATE_MESSAGE}""

else
  echo "(*) Template not found, creating"

  coder templates create --yes "${CODER_TEMPLATE_NAME}" --directory="${CODER_TEMPLATE_DIR}"

  echo "(*) Updating template metadata"

  coder templates edit --yes "${CODER_TEMPLATE_NAME}" --display-name="$(jq -r '.displayName' ${CODER_TEMPLATE_DIR}/coder.json)" --icon="$(jq -r '.icon' ${CODER_TEMPLATE_DIR}/coder.json)"
fi
