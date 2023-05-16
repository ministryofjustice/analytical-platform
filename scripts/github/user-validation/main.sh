#!/usr/bin/env bash

export GH_TOKEN="${GH_TOKEN:-$( aws secretsmanager get-secret-value --secret-id github-token --query SecretString --output text )}" # Consume ${GH_TOKEN} or default to the value in AWS Secrets Manager

# Until we restructure how users are managed in Terraform, we need to pass all the locals that contain usernames
for user in $( echo "distinct(concat(local.maintainers,local.general_members,local.engineers,local.tech_archs_maintainers,local.tech_archs_members,local.data_engineering_maintainers,local.data_engineering_members,local.data_engineering_aws_members,local.data_engineering_aws_developer_members,local.data_platform_core_infrastructure_maintainers,local.data_platform_core_infrastructure_members,local.data_platform_labs_maintainers,local.data_platform_labs_members,local.data_platform_security_auditor_members))" | terraform console | grep '"' | sed 's/"//g' | sed 's/,//g' | xargs ); do
  if [[ "$( gh api /users/${user} | jq -r '.id' )" == "null" ]]; then
    echo "User: ${user} does not exist"
    exit 1
  else
    echo "User: ${user} exists"
  fi

  if [[ "$( gh api /orgs/ministryofjustice/memberships/${user} | jq -r '.state' )" == "active" ]]; then
    echo "User: ${user} is a member of the ministryofjustice organisation"
  else
    echo "User: ${user} is not a member of the ministryofjustice organisation"
    exit 1
  fi
done
