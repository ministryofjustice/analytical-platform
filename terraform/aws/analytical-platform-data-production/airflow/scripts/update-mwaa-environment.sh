#!/usr/bin/env bash

AWS_ACCOUNT_ID=${1}
MWAA_ENVIRONMENT_NAME=${2}
AWS_REGION=${3:-eu-west-1}
AWS_ROLE=${4:-GlobalGitHubActionAdmin}

assumeRole=$(aws sts assume-role \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${AWS_ROLE} \
  --role-session-name analytical-platform-data-production-airflow)
export assumeRole

AWS_ACCESS_KEY_ID=$(echo ${assumeRole} | jq -r '.Credentials.AccessKeyId')
export AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$(echo ${assumeRole} | jq -r '.Credentials.SecretAccessKey')
export AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN=$(echo ${assumeRole} | jq -r '.Credentials.SessionToken')
export AWS_SESSION_TOKEN

aws --region "${AWS_REGION}" mwaa update-environment --name "${MWAA_ENVIRONMENT_NAME}"
