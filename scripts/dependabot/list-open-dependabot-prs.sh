#!/usr/bin/env bash
PAGER=""  # Disable pager for gh cli

# Pulled from https://github.com/ministryofjustice/data-platform-github-access/blob/main/analytical-platform-repositories.tf
REPOSITORIES=(
    "ministryofjustice/analytical-platform"
    "ministryofjustice/analytical-platform-runbooks"
    "ministryofjustice/analytical-platform-user-guide"
    "ministryofjustice/analytical-platform-dashboard"
    "ministryofjustice/analytical-platform-visual-studio-code"
    "ministryofjustice/analytical-platform-ingestion-scan"
    "ministryofjustice/analytical-platform-ingestion-transfer"
    "ministryofjustice/analytical-platform-ingestion-notify"
    "ministryofjustice/analytical-platform-jml-report"
    "ministryofjustice/analytical-platform-image-build-template"
    "ministryofjustice/analytical-platform-actions-runner"
    "ministryofjustice/analytical-platform-rshiny-open-source-base"
    "ministryofjustice/analytical-platform-kubectl"
    "ministryofjustice/analytical-platform-mlflow",
    "ministryofjustice/analytical-platform-action-runner"
)

echo -e "🤖 Open Dependabots \n"

total_open_prs=0

for REPO in "${REPOSITORIES[@]}"; do
    echo "$REPO:"

    # Use gh cli to list pull requests with the label 'dependencies'
    pr_list=$(gh pr list --repo $REPO --label "dependencies" --state open --json number,title,url,createdAt -q '.[] | "\(.number) | \(.url) | \(.title)"')

    pr_count=$(echo "$pr_list" | grep -c " | ")
    total_open_prs=$((total_open_prs + pr_count))
    echo "$pr_list"
    echo ""
    echo "--------------------------------------------------------------"
done

echo -e "📊 Total Open Dependabot PRs: $total_open_prs \n"
