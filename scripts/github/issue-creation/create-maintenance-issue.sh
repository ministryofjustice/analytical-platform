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
