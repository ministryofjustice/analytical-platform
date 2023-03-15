#!/bin/bash

source_repo=''
target_repo=''

while getopts 's:t:' flag; do
  case "${flag}" in
    s) source_repo="${OPTARG}" ;;
    t) target_repo="${OPTARG}" ;;
  esac
done

if [[ $(git --no-pager log -i -E --all --grep="Merge branch 'main' of github.com:ministryofjustice/data-platform-app-template") ]]; then
    echo "template has been merged in, exiting..."
    exit $?
else
    echo "Has not been processed, continuing..."
fi

export WORKING_DIR=./

# setting repo details
export SOURCE_ORG="moj-analytical-services"
export TARGET_ORG="ministryofjustice"

export SOURCE_REPO=$source_repo
export SOURCE_REPO_URL="git@github.com:${SOURCE_ORG}/${SOURCE_REPO}.git"
export TARGET_REPO=$target_repo
export TARGET_REPO_URL="git@github.com:${TARGET_ORG}/${TARGET_REPO}.git"
export TEMPLATE_REPO=data-platform-app-template
export TEMPLATE_REPO_URL="git@github.com:${TARGET_ORG}/${TEMPLATE_REPO}.git"

# Clone the source repository and set the target repository as its new remote origin
cd $WORKING_DIR
git clone --bare $SOURCE_REPO_URL
cd ${WORKING_DIR}/${SOURCE_REPO}.git
git remote set-url --push origin $TARGET_REPO_URL

# Fetch all branches and tags from the source repository,
# then push them to the target repository using the --mirror option
git fetch -p origin
git push --mirror

# Clone the target repository and merge the main branch with the origin/master branch,
# resolving any conflicts in favor of the source branch
cd $WORKING_DIR
git clone $TARGET_REPO_URL

cd ${WORKING_DIR}/${TARGET_REPO}
git fetch --all
if git show-ref --quiet refs/heads/master; then
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

# reset config options on repo
git config --unset pull.rebase
git remote remove template

git push
