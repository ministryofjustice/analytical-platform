#!/usr/bin/env bash

aws-sso login

if [[ -z "${AWS_SSO}" ]]; then
  aws-sso exec --profile ${AWS_SSO_PROFILE} -- \
    aws eks get-token \
      --region ${AWS_REGION} \
      --cluster-name ${AWS_EKS_CLUSTER_NAME}
else
  aws eks get-token \
    --region ${AWS_REGION} \
    --cluster-name ${AWS_EKS_CLUSTER_NAME}
fi
