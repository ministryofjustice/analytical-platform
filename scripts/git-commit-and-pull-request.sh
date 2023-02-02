#!/bin/bash

set -euo pipefail

  TOKEN=$GITHUB_TOKEN


# Define commit information
file_to_commit="${1}/dependabot.yml"
branch="date-$(date +%s)"
commit_message="Workflow: created files in ${1}"
content=$( base64 -i $file_to_commit )
main_branch_sha=$(git rev-parse origin/main)

git checkout -b "$branch"
git add "$1"
git commit -m "$commit_message"

git branch -a

echo "Computing sha"
sha=$( git rev-parse $branch:$file_to_commit)

echo "Create branch on remote"

# Create branch on remote
gh api --method POST /repos/:owner/:repo/git/refs \
  --field ref="refs/heads/$branch" \
  --field sha="$main_branch_sha"

# Create signed commit
gh api --method PUT /repos/:owner/:repo/contents/$file_to_commit \
  --field message="$commit_message" \
  --field content="$content" \
  --field encoding="base64" \
  --field branch="$branch" \
  --field sha="$sha"

# Define: repository URL, branch, title, and PR body
repository_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls"
pull_request_title="New files for dependabot"
pull_request_body="> This PR was automatically created via a GitHub action workflow 🤖

This PR commits new files under ${1}."

# Check if changes to create PR
if [ "$(git rev-parse origin/main)" = "$(git rev-parse $branch)" ]; then
  echo "No difference in branches to create PR, exiting."
  exit 0
fi
echo "Creating Payload"

payload=$(echo "${pull_request_body}" | jq --arg branch "$branch" --arg pr_title "$pull_request_title" -R --slurp '{ body: ., base: "main", head: $branch, title: $pr_title }')

echo "${payload}" | curl \
  -s -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${GH_TOKEN}" \
  -d @- $repository_url > /dev/null
ERRORCODE="${?}"
if [ ${ERRORCODE} -ne 0 ]
then
  echo "ERROR: git-commit-and-pull-request.sh exited with an error - Code:${ERRORCODE}"
  exit 1
fi
