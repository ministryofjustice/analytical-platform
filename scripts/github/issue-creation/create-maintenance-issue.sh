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
echo $new_issue_url

project_view=$(gh project view 27 --owner ministryofjustice --format=json)
count_of_project_items=$(echo "$project_view" | jq '.items[]')
echo $count_of_project_items

project_id=$(echo "$project_view" | jq -r '.id')
echo $project_id

project_item_id=$(gh project item-list 27 \
  --owner ministryofjustice \
  --limit="$count_of_project_items" \
  --format=json \
  | jq -r --arg url "$new_issue_url" '.items[] | select(.content.url==$url) | .id')
echo $project_item_id

field_list=$(gh project field-list 27 --owner "ministryofjustice" --format=json)
echo $field_list

kanban_status_field_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Kanban Status") | .id')
echo $kanban_status_field_id
kanban_status_ready_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Kanban Status") | .options[] | select(.name=="Ready") | .id')
echo $kanban_status_ready_id
refined_field_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Refined") | .id')
echo $refined_field_id
refined_yes_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Refined") | .options[] | select(.name=="Yes") | .id')
echo $refined_yes_id
estimation_field_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Estimation") | .id')
echo $estimation_field_id
estimation_2_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Estimation") | .options[] | select(.name=="2") | .id')
echo $estimation_2_id
priority_field_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Priority") | .id')
echo $priority_field_id
priority_medium_id=$(echo "$field_list" | jq -r '.fields[] | select(.name=="Priority") | .options[] | select(.name=="Medium") | .id')
echo $priority_medium_id

gh project item-edit --project-id "$project_id" --id "$project_item_id" --field-id "$kanban_status_field_id"  --single-select-option-id "$kanban_status_ready_id"
gh project item-edit --project-id "$project_id" --id "$project_item_id" --field-id "$refined_field_id"  --single-select-option-id "$refined_yes_id"
gh project item-edit --project-id "$project_id" --id "$project_item_id" --field-id "$estimation_field_id"  --single-select-option-id "$estimation_2_id"
gh project item-edit --project-id "$project_id" --id "$project_item_id" --field-id "$priority_field_id"  --single-select-option-id "$priority_medium_id"
