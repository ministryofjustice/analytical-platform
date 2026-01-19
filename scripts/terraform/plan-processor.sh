#!/usr/bin/env bash

# This is an experimental script to process a Terraform plan file and output a summary of changes.
# terraform plan -out=plan.tfplan && bash scripts/terraform/plan-processor.sh plan.tfplan

INPUT_PLAN="${1:-plan.tfplan}"

print_resources() {
  local symbol=$1
  local title=$2
  local jq_filter=$3

  local resources
  resources=$(echo "${PLAN_JSON}" | jq -r "${jq_filter}")

  if [[ -n "${resources}" ]]; then
    echo "### ${title}"
    echo ""
    echo '```diff'
    echo "${resources}" | while IFS= read -r address; do
      [[ -n "${address}" ]] && echo "${symbol} ${address}"
    done
    echo '```'
    echo ""
  fi
}

# Check if plan file exists
if [[ ! -f "${INPUT_PLAN}" ]]; then
  echo "Error: Plan file '${INPUT_PLAN}' not found" >&2
  exit 1
fi

# Extract all resource changes once
PLAN_JSON=$(terraform show -json "${INPUT_PLAN}")

# Count changes by type
CREATE_COUNT=$(echo "${PLAN_JSON}" | jq '[.resource_changes[] | select(.change.actions | contains(["create"]) and (contains(["delete"]) | not))] | length')
UPDATE_COUNT=$(echo "${PLAN_JSON}" | jq '[.resource_changes[] | select(.change.actions == ["update"])] | length')
DELETE_COUNT=$(echo "${PLAN_JSON}" | jq '[.resource_changes[] | select(.change.actions | contains(["delete"]) and (contains(["create"]) | not))] | length')
REPLACE_COUNT=$(echo "${PLAN_JSON}" | jq '[.resource_changes[] | select(.change.actions | length == 2 and contains(["create", "delete"]))] | length')
TOTAL_CHANGES=$((CREATE_COUNT + UPDATE_COUNT + DELETE_COUNT + REPLACE_COUNT))

# Print summary header
echo "# Terraform Plan Summary"

if [[ ${TOTAL_CHANGES} -eq 0 ]]; then
  echo ""
  echo "✅ No changes. Infrastructure matches the configuration."
  exit 0
fi

echo ""
echo "${CREATE_COUNT} to create, ${UPDATE_COUNT} to update, ${REPLACE_COUNT} to replace, ${DELETE_COUNT} to delete."
echo ""

# Print detailed changes
if [[ ${TOTAL_CHANGES} -gt 0 ]]; then
  echo "## Detailed Changes"
  echo ""

  # Creates (excluding replacements)
  print_resources \
    "+" \
    "Resources to be created" \
    '.resource_changes[] | select(.change.actions | contains(["create"]) and (contains(["delete"]) | not)) | .address'

  # Updates
  print_resources \
    "!" \
    "Resources to be updated" \
    '.resource_changes[] | select(.change.actions == ["update"]) | .address'

  # Replacements
  print_resources \
    "-+" \
    "Resources to be replaced" \
    '.resource_changes[] | select(.change.actions | length == 2 and contains(["create", "delete"])) | .address'

  # Deletes (excluding replacements)
  print_resources \
    "-" \
    "Resources to be deleted" \
    '.resource_changes[] | select(.change.actions | contains(["delete"]) and (contains(["create"]) | not)) | .address'
fi

if [[ "${GITHUB_ACTIONS}" == "true" ]]; then
  echo "## Source"
  echo ""
  echo "<table>"
  echo "<tr><td><strong>Actor</strong></td><td>@${GITHUB_ACTOR}</td></tr>"
  echo "<tr><td><strong>Commit</strong></td><td><a href=\"https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}\"><code>${GITHUB_SHA}</code></a></td></tr>"
  echo "<tr><td><strong>Workflow</strong></td><td><a href=\"https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}\">View run</a></td></tr>"
  echo "</table>"
fi
