#!/usr/bin/env bash
set -euo pipefail

REGION="eu-west-2"
GITHUB_RAW_URL="https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-environments/213a7f7b259067520f77105ba390f7f1a2566119/terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf"

# Fetch eks_cluster_version from GitHub
EKS_CLUSTER_VERSION=$(curl -sSL "$GITHUB_RAW_URL" \
  | grep -E '^\s*eks_cluster_version\s*=' \
  | head -n1 \
  | sed -E 's/.*=\s*"([^"]+)"/\1/')

# Fetch and extract eks_cluster_addon_versions block
echo "Fetching eks_cluster_addon_versions from GitHub..."
raw_block=$(curl -sSL "$GITHUB_RAW_URL" \
  | sed -n '/^ *eks_cluster_addon_versions *= *{/,/^ *}/p' \
  | sed '1d;$d' \
  | grep -E '^[[:space:]]*[a-zA-Z0-9_-]+[[:space:]]*=' | grep -v '^ *eks_cluster_addon_versions *= *{')

# Populate associative array
declare -A eks_cluster_addon_versions
while IFS='=' read -r key val; do
  key=$(echo "$key" | xargs | tr -d '"')
  val=$(echo "$val" | xargs | tr -d '"')
  eks_cluster_addon_versions["$key"]="$val"
done <<< "$raw_block"

declare -A updated_versions

echo
echo "Checking addon versions for Kubernetes $EKS_CLUSTER_VERSION in region $REGION"
echo

for tf_key in "${!eks_cluster_addon_versions[@]}"; do
  current_version="${eks_cluster_addon_versions[$tf_key]}"
  aws_addon_name="${tf_key//_/-}"

  latest_version=$(aws eks describe-addon-versions \
      --region "$REGION" \
      --kubernetes-version "$EKS_CLUSTER_VERSION" \
      --addon-name "$aws_addon_name" \
      --query 'addons[].addonVersions[].addonVersion' \
      --output text 2>/dev/null | tr '\t' '\n' | sort -V | tail -n 1)

  updated_versions["$tf_key"]="$latest_version"

  echo "$tf_key:"
  echo "  Current version: $current_version"
  echo "  Latest version : $latest_version"

  if [[ "$current_version" == "$latest_version" || -z "$latest_version" ]]; then
    echo "  ✅ Up to date"
  else
    echo "  ⚠️  Update available"
  fi
  echo
done

# Emit updated Terraform block
echo "Updated eks_cluster_addon_versions = {"
for tf_key in "${!updated_versions[@]}"; do
  version="${updated_versions[$tf_key]}"
  printf "    %-35s = \"%s\"\n" "$tf_key" "$version"
done
echo "}"

echo ""
echo "Checking latest Bottlerocket AMI version..."

# Extract eks_node_version from GitHub
EKS_NODE_VERSION=$(curl -sSL "$GITHUB_RAW_URL" \
  | grep -E '^\s*eks_node_version\s*=' \
  | head -n1 \
  | sed -E 's/.*=\s*"([^"]+)"/\1/')

echo "NOTE: eks_node_version is: '$EKS_NODE_VERSION'"

# Build SSM path for latest Bottlerocket image_version
SSM_PATH="/aws/service/bottlerocket/aws-k8s-${EKS_CLUSTER_VERSION}/x86_64/latest/image_version"

# Get latest Bottlerocket version from SSM
LATEST_NODE_RELEASE=$(aws ssm get-parameter \
  --region "$REGION" \
  --name "$SSM_PATH" \
  --query 'Parameter.Value' \
  --output text 2>/dev/null)

echo "🚀 Latest Bottlerocket image_version: $LATEST_NODE_RELEASE"

if [[ "$EKS_NODE_VERSION" == "$LATEST_NODE_RELEASE" ]]; then
  echo "✅ Bottlerocket node version is up to date"
else
  echo "⚠️  Newer Bottlerocket node version available: $LATEST_NODE_RELEASE"
fi


