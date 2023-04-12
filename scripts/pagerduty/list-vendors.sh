#!/usr/bin/env/ bash

export PAGERDUTY_TOKEN="${PAGERDUTY_TOKEN:-$( aws secretsmanager get-secret-value --secret-id pagerduty-token --query SecretString --output text )}" # Consume ${PAGERDUTY_TOKEN} or default to the value in AWS Secrets Manager

for offset in 0 100 200 300 400; do # As of 12/04/2023 the API has 5 pages of vendors
  echo "Getting vendors from offset ${offset}"
  curl \
    --silent \
    --request GET \
    --url "https://api.pagerduty.com/vendors?limit=100&offset=${offset}" \
    --header "Accept: application/vnd.pagerduty+json;version=2" \
    --header "Authorization: Token token=${PAGERDUTY_TOKEN}" \
    --header 'Content-Type: application/json' | jq -r '.vendors[].name'
done
