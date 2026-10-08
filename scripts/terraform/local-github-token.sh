#!/usr/bin/env bash
set -euo pipefail

# Mints a short-lived GitHub token for local Terraform runs by assuming the
# octo-sts-local-terraform role (terraform/aws/analytical-platform-management-production/
# octo-sts-local-terraform-runs), requesting an AWS outbound identity federation token,
# and exchanging it with Octo STS using the org-member-reader-local identity
# (.github/chainguard/org-member-reader-local.sts.yaml).
#
# Requires you to be authenticated to AWS (e.g. via aws-sso login) with access to
# assume the role below in analytical-platform-management-production.
#
# Usage: eval "$(scripts/terraform/local-github-token.sh)"

ROLE_ARN="arn:aws:iam::042130406152:role/octo-sts-local-terraform"
IDENTITY="org-member-reader-local"
SCOPE="ministryofjustice/analytical-platform"
AUDIENCE="octo-sts.dev"

ASSUMED_ROLE_CREDENTIALS=$(
  aws sts assume-role \
    --role-arn "${ROLE_ARN}" \
    --role-session-name "octo-sts-local-terraform" \
    --duration-seconds 900 \
    --query Credentials \
    --output json
)

AWS_OIDC_TOKEN=$(
  AWS_ACCESS_KEY_ID=$(echo "${ASSUMED_ROLE_CREDENTIALS}" | jq -r '.AccessKeyId') \
  AWS_SECRET_ACCESS_KEY=$(echo "${ASSUMED_ROLE_CREDENTIALS}" | jq -r '.SecretAccessKey') \
  AWS_SESSION_TOKEN=$(echo "${ASSUMED_ROLE_CREDENTIALS}" | jq -r '.SessionToken') \
  aws sts get-web-identity-token \
    --region eu-west-2 \
    --audience "${AUDIENCE}" \
    --signing-algorithm RS256 \
    --duration-seconds 60 \
    --query WebIdentityToken \
    --output text
)

GITHUB_TOKEN=$(
  curl --fail --silent --show-error \
    -H "Authorization: Bearer ${AWS_OIDC_TOKEN}" \
    "https://${AUDIENCE}/sts/exchange?scope=${SCOPE}&identity=${IDENTITY}" \
    | jq -r '.token'
)

echo "export TF_VAR_org_member_reader_github_token=${GITHUB_TOKEN}"
