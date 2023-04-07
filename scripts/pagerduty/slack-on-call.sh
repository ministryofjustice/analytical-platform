#!/usr/bin/env/ bash

export PAGERDUTY_TOKEN="${PAGERDUTY_TOKEN:-$( aws secretsmanager get-secret-value --secret-id pagerduty-token --query SecretString --output text )}" # Consume ${PAGERDUTY_TOKEN} or default to the value in AWS Secrets Manager
export PAGERDUTY_ESCALATION_POLICY_ID="${PAGERDUTY_ESCALATION_POLICY_ID:-"PM8NPPK"}" # Consume ${PAGERDUTY_ESCALATION_POLICY_ID} or default to Data Platform's escalation policy

curl \
  --silent \
  --request GET \
  --url https://api.pagerduty.com/oncalls \
  --header "Accept: application/vnd.pagerduty+json;version=2" \
  --header "Authorization: Token token=${PAGERDUTY_TOKEN}" \
  --header "Content-Type: application/json" | jq -r '.oncalls[] | select(.escalation_policy.id == "'${PAGERDUTY_ESCALATION_POLICY_ID}'") | .user.summary'
