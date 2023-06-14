#!/bin/bash

# Fail on errors and unset variables; ensure pipes don't mask error codes
set -euo pipefail

ACCOUNT_ID=""
ROLE_NAME=""
CLUSTER_ID=""

function usage {
    echo "Error: $1" >&2
    echo "" >&2
    echo "Usage:" >&2
    echo "" >&2
    echo "Checks whether a redshift cluster is available and reports the result." >&2
    echo "Returns non-zero result if the cluster is not available." >&2
    echo "" >&2
    echo "$(basename $0) -a ACCOUNT_ID -r ROLE_NAME -c CLUSTER_ID" >&2
    echo "" >&2
    exit 1
}

# Parse command line options
while getopts ":a:r:c:" opt
do
    case $opt in 
        a)
            ACCOUNT_ID=$OPTARG
            ;;
        r)
            ROLE_NAME=$OPTARG
            ;;
        c)
            CLUSTER_ID=$OPTARG
            ;;
        \?)
            usage "invalid option -$OPTARG"
        ;;
        :)
            usage "-$OPTARG requires an argument"
        ;;
    esac
done

# Check all options are set
[[ -z "$ACCOUNT_ID" ]] && usage "ACCOUNT_ID must be provided"
[[ -z "$ROLE_NAME" ]] && usage "ROLE_NAME must be provided"
[[ -z "$CLUSTER_ID" ]] && usage "CLUSTER_ID must be provided"

# Check required binaries are installed
which jq >/dev/null || usage "jq must be installed"
which aws >/dev/null || usage "aws must be installed"

# This script may leak some credentials so we make the assume role session as
# limited as possible

# The role which to assume to perform the check
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"

# The session policy to apply
SESSION_POLICY="arn:aws:iam::aws:policy/AmazonRedshiftReadOnlyAccess"

# 900 Seconds is the minimum allowed by AWS APIs
SESSION_DURATION_SECS=900

ASSUME_RESULT=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name check-redshift --duration "$SESSION_DURATION_SECS" --policy-arns "arn=$SESSION_POLICY")

export AWS_ACCESS_KEY_ID=$(echo $ASSUME_RESULT | jq -rc '.Credentials.AccessKeyId')
export AWS_SESSION_TOKEN=$(echo $ASSUME_RESULT | jq -rc '.Credentials.SessionToken')
export AWS_SECRET_ACCESS_KEY=$(echo $ASSUME_RESULT | jq -rc '.Credentials.SecretAccessKey')

# Get status
CLUSTER_STATUS=$(aws redshift describe-clusters --cluster-identifier $CLUSTER_ID | jq -rc ".Clusters[] | .ClusterStatus")

echo "Cluster status: $CLUSTER_STATUS"

# Fail if not available
if [ "$CLUSTER_STATUS" != "available" ]; then
    exit 1
fi
