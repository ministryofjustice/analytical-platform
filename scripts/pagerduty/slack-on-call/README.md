# PagerDuty Slack On-Call

This script:

1. obtains the on-call user for the given schedule

1. gets the on-call user's Slack handle

1. posts a message to the given Slack channel

It is designed to be executed every morning by `.github/workflows/platform-pagerduty-on-call.yml`

## Testing Locally
<!-- markdownlint-disable MD013 -->
```bash
# Drop into AWS Vault
aws-vault exec analytical-platform-management-production

# Change into script directory
cd scripts/pagerduty/slack-on-call

# Run Python container
docker run -it --rm \
  --entrypoint /bin/sh \
  --volume $( pwd ):/app \
  --workdir /app \
  --env PAGERDUTY_SCHEDULE_ID="REPLACE_ME" \
  --env PAGERDUTY_TOKEN="$( aws secretsmanager get-secret-value --secret-id pagerduty-token --query SecretString --output text )" \
  --env SLACK_CHANNEL="REPLACE_ME" \
  --env SLACK_TOKEN="$( aws secretsmanager get-secret-value --secret-id slack-pagerduty-on-call-token --query SecretString --output text )" \
  public.ecr.aws/docker/library/python:3.9

# Install requirements
pip install --requirement requirements.txt

# Run script

python main.py
```
<!-- markdownlint-enable MD013 -->
