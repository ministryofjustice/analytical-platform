if [[ "${CLOSE_PREVIOUS}" == true ]]; then
  previous_issue_number=$(gh issue list \
    --label "$LABELS" \
    --json number \
    --jq '.[0].number')
  if [[ -n $previous_issue_number ]]; then
    gh issue close "$previous_issue_number"
    gh issue unpin "$previous_issue_number"
  fi
fi
new_issue_url=$(gh issue create \
  --title "$TITLE" \
  --assignee "$ASSIGNEES" \
  --label "$LABELS" \
  --body "$BODY")
if [[ $PINNED == true ]]; then
  gh issue pin "$new_issue_url"
fi
echo "Created new issue: ${new_issue_url}"
sleep 30
project_view=$(gh project view 27 --owner ministryofjustice --format=json)
count_of_project_items=$(echo "$project_view" | jq '.items[]')
project_id=$(echo "$project_view" | jq -r '.id')
echo "Getting Project V2 Item (PVTI) ID for new issue: ${new_issue_url}, using page limit: ${count_of_project_items}"
project_item_id=$(gh project item-list 27 \
  --owner ministryofjustice \
  --limit="$count_of_project_items" \
  --format=json \
  | jq -r --arg url "$new_issue_url" '.items[] | select(.content.url==$url) | .id')

if [[ -z "$project_item_id" ]]; then
  echo "❌Error: Could not find Project V2 Item ID for issue: ${new_issue_url}"
  exit 1
fi

echo "Getting Project Field List for Project Analytical Platform (Project 27)"
field_list=$(gh project field-list 300 --owner "ministryofjustice" --format=json)
if [[ -z "$field_list" ]]; then
  echo "❌ Error: Could not find Field List for project: Analytical Platform (Project 27)"
  exit 1
fi
kanban_status_field_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Kanban Status") | .id')
kanban_status_ready_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Kanban Status") | .options[] | select(.name=="Ready") | .id')
refined_field_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Refined") | .id')
refined_yes_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Refined") | .options[] | select(.name=="Yes") | .id')
estimation_field_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Estimation") | .id')
estimation_2_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Estimation") | .options[] | select(.name=="2") | .id')
priority_field_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Priority") | .id')
priority_medium_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Priority") | .options[] | select(.name=="Medium") | .id')

gh project item-edit --project-id "$project_id" --id "$project_item_id" --field-id "$kanban_status_field_id"  --single-select-option-id "$kanban_status_ready_id"
gh project item-edit --project-id "$project_id" --id "$project_item_id" --field-id "$refined_field_id"  --single-select-option-id "$refined_yes_id"
gh project item-edit --project-id "$project_id" --id "$project_item_id" --field-id "$estimation_field_id"  --single-select-option-id "$estimation_2_id"
gh project item-edit --project-id "$project_id" --id "$project_item_id" --field-id "$priority_field_id"  --single-select-option-id "$priority_medium_id"

echo "🎉 Updated Analytical Platform Project Item fields: Kanban Status, Refined, Estimation, Priority"
