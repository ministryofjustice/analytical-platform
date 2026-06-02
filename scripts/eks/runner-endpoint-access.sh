#!/usr/bin/env bash
set -euo pipefail

# Temporarily grants (or revokes) the current GitHub runner's egress IP access to
# an EKS cluster's public API endpoint, so Terraform, kubectl and Helm can reach
# it during a plan or apply.
#
# This script is environment-agnostic: the target AWS account is derived from the
# component's terraform.tfvars, so it works for any "*-cluster" component (for
# example development and production) without hard-coded account IDs.
#
# Usage:
#   scripts/eks/runner-endpoint-access.sh allow  <working-directory>
#   scripts/eks/runner-endpoint-access.sh revoke <working-directory>

MODE="${1:?Usage: ${0} <allow|revoke> <working-directory>}"
WORKING_DIRECTORY="${2:?Usage: ${0} <allow|revoke> <working-directory>}"

# The EKS clusters live in eu-west-1; pin the region so every call targets it
# regardless of the runner's default region (overridable via AWS_REGION)
AWS_REGION="${AWS_REGION:-eu-west-1}"
export AWS_REGION AWS_DEFAULT_REGION="${AWS_REGION}"

STATE_FILE="${RUNNER_TEMP:-/tmp}/eks-endpoint-access.env"

# Derive the environment alias from the path, for example
# terraform/aws/analytical-platform-development/cluster -> analytical-platform-development
ENVIRONMENT_ALIAS="$(basename "$(dirname "${WORKING_DIRECTORY}")")"

# Resolve the target account ID from the component's account_ids map in tfvars
ACCOUNT_ID="$(grep -E "^[[:space:]]*${ENVIRONMENT_ALIAS}[[:space:]]*=" "${WORKING_DIRECTORY}/terraform.tfvars" | grep -oE '[0-9]{12}' | head -1)"

if [[ -z "${ACCOUNT_ID}" ]]; then
  echo "ERROR: Could not determine AWS account ID for environment '${ENVIRONMENT_ALIAS}'" >&2
  exit 1
fi

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/GlobalGitHubActionAdmin"

# Assume the target account role so we can manage the EKS endpoint.
# Set SKIP_ASSUME_ROLE=1 to use the caller's existing credentials instead, which
# is useful for local testing when already authenticated in the target account.
if [[ "${SKIP_ASSUME_ROLE:-0}" == "1" ]]; then
  echo "SKIP_ASSUME_ROLE set; using existing credentials (not assuming ${ROLE_ARN})"
else
  credentials="$(aws sts assume-role \
    --region "${AWS_REGION}" \
    --role-arn "${ROLE_ARN}" \
    --role-session-name "eks-endpoint-${MODE}" \
    --query 'Credentials' \
    --output json)"
  AWS_ACCESS_KEY_ID="$(echo "${credentials}" | jq -r '.AccessKeyId')"
  AWS_SECRET_ACCESS_KEY="$(echo "${credentials}" | jq -r '.SecretAccessKey')"
  AWS_SESSION_TOKEN="$(echo "${credentials}" | jq -r '.SessionToken')"
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
fi

# Apply a public access CIDR set to a cluster, tolerating the no-op case where
# the cluster is already at the desired configuration, and only waiting for the
# cluster to settle when an update was actually started.
update_endpoint_cidrs() {
  local cluster_name="$1"
  local cidrs_csv="$2"
  local output

  if output="$(aws eks update-cluster-config \
    --region "${AWS_REGION}" \
    --name "${cluster_name}" \
    --resources-vpc-config "endpointPublicAccess=true,publicAccessCidrs=${cidrs_csv}" 2>&1)"; then
    aws eks wait cluster-active --region "${AWS_REGION}" --name "${cluster_name}"
    return 0
  fi

  # A no-op update is not an error for our purposes
  if echo "${output}" | grep -q "already at the desired configuration"; then
    echo "Cluster ${cluster_name} already at the desired configuration; no change made"
    return 0
  fi

  echo "ERROR: Failed to update EKS endpoint configuration for ${cluster_name}" >&2
  return 1
}

case "${MODE}" in
  allow)
    CLUSTER_NAME="$(aws eks list-clusters --region "${AWS_REGION}" --query 'clusters[0]' --output text)"
    RUNNER_IP="$(curl --silent --fail https://checkip.amazonaws.com)"

    if [[ ! "${RUNNER_IP}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
      echo "ERROR: Could not determine a valid runner IP (got '${RUNNER_IP}')" >&2
      exit 1
    fi

    ORIGINAL_CIDRS="$(aws eks describe-cluster \
      --region "${AWS_REGION}" \
      --name "${CLUSTER_NAME}" \
      --query 'cluster.resourcesVpcConfig.publicAccessCidrs' \
      --output json)"

    # If the endpoint is already open to the world, no temporary access is needed
    if echo "${ORIGINAL_CIDRS}" | jq -e 'index("0.0.0.0/0")' >/dev/null; then
      echo "Endpoint already allows 0.0.0.0/0; no temporary access required"
      rm -f "${STATE_FILE}"
      exit 0
    fi

    ORIGINAL_CSV="$(echo "${ORIGINAL_CIDRS}" | jq -r 'join(",")')"
    NEW_CSV="$(echo "${ORIGINAL_CIDRS}" | jq -r --arg ip "${RUNNER_IP}/32" '. + [$ip] | unique | join(",")')"

    echo "Cluster: ${CLUSTER_NAME}"
    echo "Granting runner IP ${RUNNER_IP}/32 temporary access to the EKS public endpoint"

    # Persist state so the revoke step can restore the original CIDRs
    {
      echo "EKS_CLUSTER_NAME=${CLUSTER_NAME}"
      echo "EKS_ORIGINAL_CIDRS=${ORIGINAL_CSV}"
    } >"${STATE_FILE}"

    update_endpoint_cidrs "${CLUSTER_NAME}" "${NEW_CSV}"
    ;;
  revoke)
    if [[ ! -f "${STATE_FILE}" ]]; then
      echo "No state file found at ${STATE_FILE}; nothing to revoke"
      exit 0
    fi

    # shellcheck disable=SC1090
    source "${STATE_FILE}"

    echo "Restoring original EKS public access CIDRs for ${EKS_CLUSTER_NAME}"

    update_endpoint_cidrs "${EKS_CLUSTER_NAME}" "${EKS_ORIGINAL_CIDRS}"

    rm -f "${STATE_FILE}"
    ;;
  *)
    echo "Usage: ${0} <allow|revoke> <working-directory>" >&2
    exit 1
    ;;
esac
