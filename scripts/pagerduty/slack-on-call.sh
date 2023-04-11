#!/usr/bin/env/ bash

export _TODAY="$( date --iso-8601 )"
export PAGERDUTY_TOKEN="${PAGERDUTY_TOKEN:-$( aws secretsmanager get-secret-value --secret-id pagerduty-token --query SecretString --output text )}" # Consume ${PAGERDUTY_TOKEN} or default to the value in AWS Secrets Manager
export PAGERDUTY_SCHEDULE_ID="${PAGERDUTY_SCHEDULE_ID:-"POE95CC"}" # Consume ${PAGERDUTY_SCHEDULE_ID} or default to Data Platform's escalation policy

curl \
  --silent \
  --request GET \
  --url "https://api.pagerduty.com/schedules/${PAGERDUTY_SCHEDULE_ID}/users?since=${_TODAY}T09%3A00Z&until=${_TODAY}T17%3A00Z" \
  --header "Accept: application/vnd.pagerduty+json;version=2" \
  --header "Authorization: Token token=${PAGERDUTY_TOKEN}" \
  --header 'Content-Type: application/json' | jq -r '.users[].name'
