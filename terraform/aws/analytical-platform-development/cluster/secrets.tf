##################################################
# Secret scan test secrets
##################################################

resource "aws_secretsmanager_secret" "dev_test_1" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "dev-test-1"
  description = "Test secret with an expiry date"

  tags = {
    expiry-date     = "2026-12-31"
    source-location = "the location the key needs updating"
  }
}

resource "aws_secretsmanager_secret" "dev_test_2" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "dev-test-2"
  description = "Test secret with an expiry date"

  tags = {
    expiry-date     = "2026-09-20"
    source-location = "the location the key needs updating"
  }
}

resource "aws_secretsmanager_secret" "dev_test_3" {
  provider = aws.analytical-platform-management-production-eu-west-1
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "dev-test-3"
  description = "Test secret with an expiry date"

  tags = {
    expiry-date     = "2026-09-6"
    source-location = "the location the key needs updating"
  }
}
