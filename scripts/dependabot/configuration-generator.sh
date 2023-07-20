#!/usr/bin/env bash

declare -xr DEPENDABOT_CONFIGURATION_FILE=".github/dependabot.yml"

dockerFolders=$(find . -type f -name "*Dockerfile*" -exec dirname {} \; | sort -h | uniq | cut -c 3-)
pythonFolders==$(find . -type f -name "*requirements*.txt" -exec dirname {} \; | sort -h | uniq | cut -c 3-)
terraformFolders=$(find . -type f -name ".terraform.lock.hcl" -exec dirname {} \; | sort -h | uniq | cut -c 3-)

echo "=== Docker Folders ==="
echo "${dockerFolders}"

echo "=== Python Folders ==="
echo "${pythonFolders}"

echo "=== Terraform Folders ==="
echo "${terraformFolders}"

echo "Generating ${DEPENDABOT_CONFIGURATION_FILE}"
cat >"${DEPENDABOT_CONFIGURATION_FILE}" <<EOL
---
# This file is auto-generated here, do not manually amend.
# https://github.com/ministryofjustice/data-platform/blob/main/scripts/dependabot/configuration-generator.sh

version: 2

updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "daily"
      time: "09:00"
      timezone: "Europe/London"
    commit-message:
      prefix: "github-actions"
      include: "scope"
    reviewers:
      - "ministryofjustice/data-platform-core-infra"
EOL

for folder in ${dockerFolders}; do
  printf "  - package-ecosystem: \"docker\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    directory: \"%s\"\n" "${folder}" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    schedule:\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      interval: \"daily\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      time: \"09:00\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      timezone: \"Europe/London\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    commit-message:\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      prefix: \"docker\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      include: \"scope\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    reviewers:\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      - \"ministryofjustice/data-platform-core-infra\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
done

for folder in ${pythonFolders}; do
  printf "  - package-ecosystem: \"pip\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    directory: \"%s\"\n" "${folder}" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    schedule:\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      interval: \"daily\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      time: \"09:00\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      timezone: \"Europe/London\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    commit-message:\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      prefix: \"python\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      include: \"scope\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    reviewers:\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      - \"ministryofjustice/data-platform-core-infra\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    labels:\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      - \"dependencies\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      - \"terraform\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      - \"override-static-analysis\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
done

for folder in ${terraformFolders}; do
  printf "  - package-ecosystem: \"terraform\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    directory: \"%s\"\n" "${folder}" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    schedule:\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      interval: \"daily\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      time: \"09:00\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      timezone: \"Europe/London\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    commit-message:\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      prefix: \"terraform\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      include: \"scope\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "    reviewers:\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
  printf "      - \"ministryofjustice/data-platform-core-infra\"\n" >>"${DEPENDABOT_CONFIGURATION_FILE}"
done

if [[ "${GITHUB_ACTIONS}" == "true" ]]; then
  if git diff --exit-code ${DEPENDABOT_CONFIGURATION_FILE} > /dev/null 2>&1; then
    echo "No difference in files, exiting."
    exit 0
  else
    mainSha=$(gh api --method GET /repos/"${GITHUB_REPOSITORY}"/contents/"${DEPENDABOT_CONFIGURATION_FILE}" --field ref="main" | jq -r '.sha')
    branchSha=$(gh api --method GET /repos/"${GITHUB_REPOSITORY}"/contents/"${DEPENDABOT_CONFIGURATION_FILE}" --field ref="${GITHUB_HEAD_REF}" | jq -r '.sha')

    if [[ "${branchSha}" != "${mainSha}" ]]; then
      echo "Branch has already been updated, using branch data"
      export apiFieldSha="${branchSha}"
    else
      echo "Branch has not been updated, using main data"
      export apiFieldSha="${mainSha}"
    fi

    gh api --method PUT /repos/${GITHUB_REPOSITORY}/contents/${DEPENDABOT_CONFIGURATION_FILE} \
      --field branch="${GITHUB_HEAD_REF}" \
      --field message="Committing updated Dependabot configuration" \
      --field encoding="base64" \
      --field content="$( base64 -w 0 ${DEPENDABOT_CONFIGURATION_FILE} )" \
      --field sha="${apiFieldSha}"
  fi
else
  echo "Not running in GitHub Actions, exiting."
  exit 0
fi
