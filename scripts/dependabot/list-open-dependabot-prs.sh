#!/usr/bin/env bash

# Instructions:
# 1. Make sure you have the GitHub CLI (gh) installed on your Mac.
#    You can install it via Homebrew using the following command:
#    brew install gh
#
# 2. Authenticate the GitHub CLI with your GitHub account:
#    gh auth login
#
# And either:
# 3. Make the script executable:
#    chmod +x list-open-dependabot-prs.sh
#
# 4. Run the script:
#    ./list-open-dependabot-prs.sh
#
# Or
# 3. Run the script:
#    bash scripts/dependabot/list-open-dependabot-prs.sh
#
#
# This script lists all open Dependabot pull requests for specified repositories in
# the Ministry of Justice GitHub organization

PAGER=""  # Disable pager for gh cli

# Define the owner, repo, and path of the file
REPO_OWNER="ministryofjustice"
REPO_NAME="data-platform-github-access"
FILE_PATH="analytical-platform-repositories.tf"

# Function to fetch repository names from the file
fetch_repositories() {
    # Use gh to download the file content using the API
    local repo_file
    repo_file=$(gh api repos/$REPO_OWNER/$REPO_NAME/contents/$FILE_PATH --jq '.content' | base64 --decode)
    if [ $? -ne 0 ]; then
        echo "Failed to fetch the file using gh api. Have you run gh auth login?"
        exit 1
    fi
    # Extract repository names using awk, excluding analytics, ap-, and analytical-platform-ui
    echo "$repo_file" | awk -F'"' '/^[[:space:]]*"[a-zA-Z0-9._-]+"[[:space:]]*=[[:space:]]*\{[[:space:]]*$/ {print $2}' | grep -Ev '^(analytics|ap-|analytical-platform-ui|analytics-platform-rstudio)$'
}

# Function to check if a repository is archived
is_repo_archived() {
    local repo=$1
    archived=$(gh api repos/"$REPO_OWNER"/"$repo" --jq '.archived')
    [[ "$archived" == "true" ]]
}

# Fetch repositories
REPOSITORIES=($(fetch_repositories))

# Debug: Output the list of repositories
# echo "Debug: List of repositories:"
# for repo in "${REPOSITORIES[@]}"; do
#     echo "$repo"
# done

echo -e "\n🤖 Open Dependabots \n"

total_open_prs=0

for REPO in "${REPOSITORIES[@]}"; do
    # Skip archived repositories
    if is_repo_archived "$REPO"; then
        echo "Skipping archived repository: $REPO"
        continue
    fi

    # Use gh cli to list pull requests with the label 'dependencies'
    pr_list=$(gh pr list --repo "$REPO_OWNER/$REPO" --label "dependencies" --state open --json number,title,url,createdAt -q '.[] | "\(.number) | \(.url) | \(.title)"')

    pr_count=$(echo "$pr_list" | grep -c " | ")

    # Only display repositories with open PRs
    if [ "$pr_count" -gt 0 ]; then
        echo "$REPO:"

        total_open_prs=$((total_open_prs + pr_count))

        # Format the output to include clickable URLs
        echo "$pr_list" | while IFS="|" read -r number url title; do
            echo "- [PR#$number: $title]($url)"
        done

        echo ""
        echo "--------------------------------------------------------------"
    fi
done

echo -e "📊 Total Open Dependabot PRs: $total_open_prs \n"
