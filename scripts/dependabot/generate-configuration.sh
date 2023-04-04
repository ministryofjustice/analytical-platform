#!/usr/bin/env bash

set -euo pipefail

DEPENDABOT_FILE=".github/dependabot.yml"

dockerFolders=$( find . -type f -name 'Dockerfile' | sed 's#/[^/]*$##' | sed 's/.\///'| sort | uniq )
terraformFolders=$( find . -type f -name '*.tf' | sed 's#/[^/]*$##' | sed 's/.\///'| sort | uniq )

echo "Docker Folders:"
echo "${dockerFolders}"

echo "Terraform Folders:"
echo "${terraformFolders}"

echo "Generating ${DEPENDABOT_FILE}"
cat > ${DEPENDABOT_FILE} << EOL
---
# This file is auto-generated here, do not manually amend.
# https://github.com/ministryofjustice/data-platform/blob/main/scripts/dependabot/generate-configuration.sh

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
echo "  - package-ecosystem: \"docker\"" >> ${DEPENDABOT_FILE}
echo "    directory: \"/${folder}\"" >> ${DEPENDABOT_FILE}
echo "    schedule:" >> ${DEPENDABOT_FILE}
echo "      interval: \"daily\"" >> ${DEPENDABOT_FILE}
done

for folder in ${terraformFolders}
do
echo "Generating entry for ${folder}"
echo "  - package-ecosystem: \"terraform\"" >> ${DEPENDABOT_FILE}
echo "    directory: \"/${folder}\"" >> ${DEPENDABOT_FILE}
echo "    schedule:" >> ${DEPENDABOT_FILE}
echo "      interval: \"daily\"" >> ${DEPENDABOT_FILE}
done
