#!/bin/bash

if [ ! -z "$2" ]; then
  GIT_DIR=$2
  cd $GIT_DIR
  GITHUB_REPOSITORY=$(basename `git rev-parse --show-toplevel`)
  GITHUB_REPOSITORY="ministryofjustice/$GITHUB_REPOSITORY"
  TOKEN=$TERRAFORM_GITHUB_TOKEN
else
  TOKEN=$GITHUB_TOKEN
fi
file_to_commit="${1}/dependabot.yml"
branch="date-$(date +%s)"
commit_message="Workflow: created files in ${1}"
content=$( base64 -i $file_to_commit )
main_branch_sha=$(git rev-parse HEAD)
sha=$( git rev-parse $branch:$file_to_commit )"
gh api --method POST /repos/:owner/:repo/git/refs \
  --field ref="refs/heads/$branch \
  --field sha="$main_branch_sha"

gh api --method PUT /repos/:owner/:repo/contents/$file_to_commit \
  --field message="$commit_message" \
  --field content="$content" \
  --field encoding="base64" \
  --field branch="$branch" \
  --field sha="$sha"
