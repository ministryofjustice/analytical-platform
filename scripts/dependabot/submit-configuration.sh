#!/usr/bin/env bash

set -euo pipefail

FILE_TO_COMMIT=".github/dependabot.yml"
BRANCH_NAME="updated-dependabot-configuration-$( date +'%s' )"
MAIN_BRANCH_SHA=$( git rev-parse origin/main )
COMMIT_MESSAGE="Updated Dependabot configuration"

if git diff --exit-code ${FILE_TO_COMMIT} > /dev/null 2>&1; then
  echo "No difference in files, exiting."
  exit 0
fi

git checkout -b ${BRANCH_NAME}
git add ${FILE_TO_COMMIT}

echo "Create branch on remote"
gh api \
  --method POST /repos/${GITHUB_REPOSITORY}/git/refs \
  --field ref="refs/heads/${BRANCH_NAME}" \
  --field sha="${MAIN_BRANCH_SHA}"

echo "Committing file"
gh api --method PUT /repos/${GITHUB_REPOSITORY}/contents/${FILE_TO_COMMIT} \
  --field branch="${BRANCH_NAME}" \
  --field message="${COMMIT_MESSAGE}" \
  --field encoding="base64" \
  --field content="$( base64 -w 0 ${FILE_TO_COMMIT} )" \
  --field sha="$( gh api --method GET /repos/${GITHUB_REPOSITORY}/contents/${FILE_TO_COMMIT} --field ref="main" | jq -r '.sha' )" 

echo "Creating PR"
gh api --method POST /repos/${GITHUB_REPOSITORY}/pulls \
 --field title="👨‍🔧 Updated Dependabot configuration" \
 --field body="." \
 --field head="${BRANCH_NAME}" \
 --field base="main"
