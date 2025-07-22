#!/usr/bin/env bash

# Define Kubernetes version and AWS region
K8S_VERSION="1.33"
REGION="eu-west-2"

# Define addons and their current versions
declare -A eks_cluster_addon_versions=(
    [coredns]="v1.12.1-eksbuild.2"
    [kube-proxy]="v1.33.0-eksbuild.2"
    [aws-ebs-csi-driver]="v1.44.0-eksbuild.1"
    [aws-efs-csi-driver]="v2.1.8-eksbuild.1"
    [aws-guardduty-agent]="v1.10.0-eksbuild.2"
    [aws-network-flow-monitoring-agent]="v1.0.2-eksbuild.5"
    [eks-pod-identity-agent]="v1.3.7-eksbuild.2"
    [eks-node-monitoring-agent]="v1.3.0-eksbuild.2"
    [vpc-cni]="v1.19.6-eksbuild.1"
)

declare -A updated_versions

echo "Checking latest addon versions for Kubernetes $K8S_VERSION in region $REGION..."
echo ""

for addon in "${!eks_cluster_addon_versions[@]}"; do
    latest_version=$(aws eks describe-addon-versions \
        --region "$REGION" \
        --kubernetes-version "$K8S_VERSION" \
        --addon-name "$addon" \
        --query 'addons[].addonVersions[].addonVersion' \
        --output text | tr '\t' '\n' | sort -V | tail -n 1)

    current_version=${eks_cluster_addon_versions[$addon]}
    updated_versions[$addon]=$latest_version

    echo "$addon:"
    echo "  Current version: $current_version"
    echo "  Latest version : $latest_version"

    if [[ "$current_version" == "$latest_version" ]]; then
        echo "  ✅ Up to date"
    else
        echo "  ⚠️  Update available"
    fi

    echo ""
done

# Output the updated eks_cluster_addon_versions block
echo "Updated eks_cluster_addon_versions block:"
echo ""
echo "eks_cluster_addon_versions = {"
for addon in "${!updated_versions[@]}"; do
    tf_key=$(echo "$addon" | sed -E 's/-/_/g')
    printf "    %-35s = \"%s\"\n" "$tf_key" "${updated_versions[$addon]}"
done
echo "}"
