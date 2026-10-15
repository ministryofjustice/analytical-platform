#tfsec:ignore:AVD-AWS-0098 CMK encryption is not required for this secret
resource "aws_secretsmanager_secret" "release_failure_webhook_url" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "release-failure-webhook-url"
  description = "Slack webhook URL for release failure notifications"
  kms_key_id  = "alias/aws/secretsmanager"
}

#tfsec:ignore:AVD-AWS-0098 CMK encryption is not required for this secret
resource "aws_secretsmanager_secret" "github_token" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "github-token"
  description = "Token for use in Analytical Platform/MOJ Analytical Services"
  kms_key_id  = "alias/aws/secretsmanager"
  tags = {
    credential-expiration = "2027-01-06"
    expiry-date           = "2027-01-06"
    source-location       = "moj-data-platform-robot account data-platform-github-access PAT"
  }
}

#tfsec:ignore:AVD-AWS-0098 CMK encryption is not required for this secret
resource "aws_secretsmanager_secret" "analytical_platform_dependabot_auto_approve" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "analytical-platform-dependabot-auto-approve"
  description = "Fine grained PAT used to auto-approve eligible Dependabot pull requests in the Terraform workflow"
  kms_key_id  = "alias/aws/secretsmanager"
  tags = {
    expiry-date     = "2027-01-07"
    source-location = "moj-data-platform-robot account analytical-platform-auto-approve PAT"
    rotation-policy = "none"
  }
}

##################################################
# slack webhook secret scan
##################################################

#tfsec:ignore:AVD-AWS-0098 CMK encryption is not required for this secret
resource "aws_secretsmanager_secret" "secret_scan_webhook_url" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "secret-scan-webhook-url"
  description = "Slack webhook URL for secret scan notifications"
  kms_key_id  = "alias/aws/secretsmanager"

  tags = {
    expiry-date     = "none"
    source-location = "the location the key needs updating"
    rotation-policy = "none"
  }
}

##################################################
# chainguard-image-pull-token
##################################################

import {
  to = aws_secretsmanager_secret.chainguard_image_pull_token
  identity = {
    "arn" = "arn:aws:secretsmanager:eu-west-1:042130406152:secret:chainguard-image-pull-token-thUDcP"
  }
}

#tfsec:ignore:AVD-AWS-0098 CMK encryption is not required for this secret
resource "aws_secretsmanager_secret" "chainguard_image_pull_token" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "chainguard-image-pull-token"
  description = "Token for pulling Chainguard images"
  kms_key_id  = "alias/aws/secretsmanager"

  tags = {
    expiry-date     = "2027-03-17"
    source-location = "chaninguard - chainguard_image_pull_token"
    rotation-policy = "none"
  }
}
