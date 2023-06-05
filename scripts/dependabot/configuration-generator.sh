#!/usr/bin/env bash

declare -xr DEPENDABOT_CONFIGURATION_FILE=".github/dependabot.yml"

dockerFolders=$( find . -type f -name '*Dockerfile*' | sed 's#/[^/]*$##' | sed 's/.\///'| sort | uniq )
pythonFolders=$( find . -type f -name '*requirements*.txt' | sed 's#/[^/]*$##' | sed 's/.\///'| sort | uniq )
terraformFolders=$( find . -type f -name '*.tf' | sed 's#/[^/]*$##' | sed 's/.\///'| sort | uniq )

echo "=== Docker Folders ==="
echo "${dockerFolders}"

echo "=== Python Folders ==="
echo "${pythonFolders}"

echo "=== Terraform Folders ==="
echo "${terraformFolders}"

echo "Generating ${DEPENDABOT_CONFIGURATION_FILE}"
cat > ${DEPENDABOT_CONFIGURATION_FILE} << EOL
---
# This file is auto-generated here, do not manually amend.
# https://github.com/ministryofjustice/data-platform/blob/main/scripts/dependabot/configuration-generator.sh

version: 2

updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "daily"
EOL

for folder in ${dockerFolders}
do
echo "Generating entry for ${folder}"
echo "  - package-ecosystem: \"docker\"" >> ${DEPENDABOT_CONFIGURATION_FILE}
echo "    directory: \"/${folder}\"" >> ${DEPENDABOT_CONFIGURATION_FILE}
echo "    schedule:" >> ${DEPENDABOT_CONFIGURATION_FILE}
echo "      interval: \"daily\"" >> ${DEPENDABOT_CONFIGURATION_FILE}
done

for folder in ${pythonFolders}
do
echo "Generating entry for ${folder}"
echo "  - package-ecosystem: \"pip\"" >> ${DEPENDABOT_CONFIGURATION_FILE}
echo "    directory: \"/${folder}\"" >> ${DEPENDABOT_CONFIGURATION_FILE}
echo "    schedule:" >> ${DEPENDABOT_CONFIGURATION_FILE}
echo "      interval: \"daily\"" >> ${DEPENDABOT_CONFIGURATION_FILE}
done

for folder in ${terraformFolders}
do
echo "Generating entry for ${folder}"
echo "  - package-ecosystem: \"terraform\"" >> ${DEPENDABOT_CONFIGURATION_FILE}
echo "    directory: \"/${folder}\"" >> ${DEPENDABOT_CONFIGURATION_FILE}
echo "    schedule:" >> ${DEPENDABOT_CONFIGURATION_FILE}
echo "      interval: \"daily\"" >> ${DEPENDABOT_CONFIGURATION_FILE}
done

if [[ "${GITHUB_ACTIONS}" == "true" ]]; then
  if git diff --exit-code ${DEPENDABOT_CONFIGURATION_FILE} > /dev/null 2>&1; then
    echo "No difference in files, exiting."
    exit 0
  else
    gh api --method PUT /repos/${GITHUB_REPOSITORY}/contents/${DEPENDABOT_CONFIGURATION_FILE} \
      --field branch="${GITHUB_HEAD_REF}" \
      --field message="Committing updated Dependabot configuration" \
      --field encoding="base64" \
      --field content="$( base64 -w 0 ${DEPENDABOT_CONFIGURATION_FILE} )" \
      --field sha="$( gh api --method GET /repos/${GITHUB_REPOSITORY}/contents/${DEPENDABOT_CONFIGURATION_FILE} --field ref="main" | jq -r '.sha' )"
  fi
else
  echo "Not running in GitHub Actions, exiting."
  exit 0
fi
