#!/usr/bin/env bash

# get repo arguments
read -r -d '' usage <<-EOF
  $(basename "$0") [-h] [-s SOURCE_REPO] [-t TARGET_REPO]

  Migrate repository content from repository in moj-analytical-services GitHub
  organisation to new location in ministryofjustice GitHub organisation

      -h  show this help text
      -s  source repo name in moj-analytical-services org
      -t  target repo name in ministryofjustice org
EOF

options=':hs:t:'
while getopts $options option; do
  case "$option" in
    h) echo "$usage"; exit;;
    s) SOURCE_REPO="${OPTARG}" ;;
    t) TARGET_REPO="${OPTARG}" ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
  esac
done

# mandatory arguments
if [ ! "$SOURCE_REPO" ] || [ ! "$TARGET_REPO" ]; then
  echo "arguments -s and -t must be provided"
  echo "$usage" >&2; exit 1
fi

WORKING_DIR="$PWD"
echo "SOURCE_REPO = ${SOURCE_REPO}"
echo "TARGET_REPO = ${TARGET_REPO}"

# setting repo details
SOURCE_ORG="moj-analytical-services"
TARGET_ORG="ministryofjustice"

SOURCE_REPO_URL="git@github.com:${SOURCE_ORG}/${SOURCE_REPO}.git"
TARGET_REPO_URL="git@github.com:${TARGET_ORG}/${TARGET_REPO}.git"
TEMPLATE_REPO=data-platform-app-template
TEMPLATE_REPO_URL="git@github.com:${TARGET_ORG}/${TEMPLATE_REPO}.git"

CLONE_EXIT_CODE=$(git clone $TARGET_REPO_URL)

if [[ $CLONE_EXIT_CODE -ne 0 ]]; then
  echo "repo already exists locally"
fi

cd $TARGET_REPO
MERGE_EXIT_CODE=$(git --no-pager log -i -E --all --grep="Merge branch 'main' of github.com:ministryofjustice/data-platform-app-template")

if [ -z "$MERGE_EXIT_CODE" ]; then
  echo "Repo hasn't been processed as the app template merge was not found in the git log. Continuing..."
else
  echo "Template has been merged in, skipping..."
  echo $MERGE_EXIT_CODE
  exit 1
fi

# Clone the source repository and set the target repository as its new remote origin
cd "$WORKING_DIR"
git clone --bare $SOURCE_REPO_URL
cd "${WORKING_DIR}/${SOURCE_REPO}.git"
git remote set-url --push origin $TARGET_REPO_URL

# Fetch all branches and tags from the source repository,
# then push them to the target repository using the --mirror option
git fetch -p origin
git push --mirror

# Merge the main branch of the target repo with the origin/master branch of the source repo,
# resolving any conflicts in favor of the source branch
# Not necessary if the source repo was using a 'main' branch
cd "${WORKING_DIR}/${TARGET_REPO}"
git fetch --all
if git show-ref --quiet --verify refs/remotes/origin/master; then
  git checkout main

  git merge origin/master --strategy-option theirs --allow-unrelated-histories \
  -m "Merge remote-tracking branch 'origin/master' as part of app migration"
  git push
  git push origin --delete master
fi

# Add the template repository as a remote, fetch its branches,
# and merge the template/main branch with the target repository's main branch,
# resolving any conflicts in favor of the target branch
git remote add template $TEMPLATE_REPO_URL
git fetch --all

FILE=.github/CODEOWNERS
if [ -f $FILE ]; then
  echo "File $FILE exists."
  mv $FILE ./CODEOWNERS
else
  echo "File $FILE does not exist."
fi

# checkout the template's main branch
git checkout template/main -m .github

if [ -f CODEOWNERS ]; then
  echo "File CODEOWNERS existed in original repo, overwriting template CODEOWNERS file"
  mv -f ./CODEOWNERS $FILE
else
  echo "File CODEOWNERS does not exist."
fi

git add .github/*

git commit -m "import template .github files (including workflows) as part of app migration"

git config pull.rebase false
git pull template main --strategy-option ours --allow-unrelated-histories --no-edit

# push even if current branch is 'behind' the remote
git fetch origin main:tmp
git rebase tmp || git rebase --skip
git push origin HEAD:main
git branch -D tmp

# reset config options on repo
git config --unset pull.rebase
git remote remove template

cd "$WORKING_DIR"
