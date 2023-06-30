#!/usr/bin/env bash

declare -xr PATH_FILTER_CONFIGURATION_FILE=".github/workflows/path-filter/containers.yml"

dockerFolders=$(find . -type f -name "*Dockerfile*" -exec dirname {} \; | sort -h | uniq | cut -c 3-)

echo "=== Docker Folders ==="
echo "${dockerFolders}"

echo "Generating ${PATH_FILTER_CONFIGURATION_FILE}"
cat >"${PATH_FILTER_CONFIGURATION_FILE}" <<EOL
---
# This file is auto-generated here, do not manually amend.
# https://github.com/ministryofjustice/data-platform/blob/main/scripts/path-filter/containers-generator.sh

EOL

for folder in ${dockerFolders}; do

  if [[ -f "${folder}/.containers-path-filter-ignore" ]]; then
    echo "Ignoring ${folder}"
    continue
  fi

  baseName=$(basename "${folder}")
  printf "${baseName}: ${folder}/**\n" >>"${PATH_FILTER_CONFIGURATION_FILE}"
done

if [[ "${GITHUB_ACTIONS}" == "true" ]]; then
  if git diff --exit-code ${PATH_FILTER_CONFIGURATION_FILE} > /dev/null 2>&1; then
    echo "No difference in files, exiting."
    exit 0
  else
    mainSha=$(gh api --method GET /repos/"${GITHUB_REPOSITORY}"/contents/"${PATH_FILTER_CONFIGURATION_FILE}" --field ref="main" | jq -r '.sha')
    branchSha=$(gh api --method GET /repos/"${GITHUB_REPOSITORY}"/contents/"${PATH_FILTER_CONFIGURATION_FILE}" --field ref="${GITHUB_HEAD_REF}" | jq -r '.sha')

    if [[ "${branchSha}" != "${mainSha}" ]]; then
      echo "Branch has already been updated, using branch data"
      export apiFieldSha="${branchSha}"
    else
      echo "Branch has not been updated, using main data"
      export apiFieldSha="${mainSha}"
    fi

    gh api --method PUT /repos/${GITHUB_REPOSITORY}/contents/${PATH_FILTER_CONFIGURATION_FILE} \
      --field branch="${GITHUB_HEAD_REF}" \
      --field message="Committing updated path-filter configuration" \
      --field encoding="base64" \
      --field content="$( base64 -w 0 ${PATH_FILTER_CONFIGURATION_FILE} )" \
      --field sha="${apiFieldSha}"
  fi
else
  echo "Not running in GitHub Actions, exiting."
  exit 0
fi
