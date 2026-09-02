#tfsec:ignore:AVD-AWS-0098 CMK encryption is not required for this secret
resource "aws_secretsmanager_secret" "analytical_platform_github_token" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "analytical-platform-github-token"
  description = "Fine grained PAT for use in Analytical Platform"
  kms_key_id  = "alias/aws/secretsmanager"
}

#tfsec:ignore:AVD-AWS-0098 CMK encryption is not required for this secret
resource "aws_secretsmanager_secret" "moj_analytical_services_github_token" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "moj-analytical-services-github-token"
  description = "Fine grained PAT for use in Analytical Platform for MOJ Analytical Services"
  kms_key_id  = "alias/aws/secretsmanager"
}

#tfsec:ignore:AVD-AWS-0098 CMK encryption is not required for this secret
resource "aws_secretsmanager_secret" "release_failure_webhook_url" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "release-failure-webhook-url"
  description = "Slack webhook URL for release failure notifications"
  kms_key_id  = "alias/aws/secretsmanager"
}


import {
  to = aws_secretsmanager_secret.github_token
  identity = {
    "arn" = "arn:aws:secretsmanager:eu-west-1:042130406152:secret:github-token-SAag9J"
  }
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
  }
}

# test secrets
resource "aws_secretsmanager_secret" "test_1" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "test-1"
  description = "Test secret with an expiry date"

  tags = {
    expiry-date = "2026-12-31"
    source-location = "the location the key needs updating"
  }
}

resource "aws_secretsmanager_secret" "test_2" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "test-2"
  description = "Test secret with an expiry date"

  tags = {
    expiry-date = "2026-09-20"
    source-location = "the location the key needs updating"
  }
}

resource "aws_secretsmanager_secret" "test_3" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "test-3"
  description = "Test secret with an expiry date"

  tags = {
    expiry-date = "2026-09-6"
    source-location = "the location the key needs updating"
  }
}

