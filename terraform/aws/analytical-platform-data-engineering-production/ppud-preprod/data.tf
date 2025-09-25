### Account Information

data "aws_secretsmanager_secret" "account_ids" {
  provider = aws.session
  name     = "analytical-platform/platform-account-ids"
}

data "aws_secretsmanager_secret_version" "account_ids_version" {
  provider  = aws.session
  secret_id = data.aws_secretsmanager_secret.account_ids.id
}

# Data block for AWS region
data "aws_region" "current" {}