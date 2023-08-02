##################################################
# AWS
##################################################

# Calling session
data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_data_platform_development_cluster" {
  provider = aws.analytical-platform-management-production

  secret_id = "cloud-platform/live/data-platform-development/cluster"
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_data_platform_development_ca_cert" {
  provider = aws.analytical-platform-management-production

  secret_id = "cloud-platform/live/data-platform-development/ca-cert"
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_data_platform_development_token" {
  provider = aws.analytical-platform-management-production

  secret_id = "cloud-platform/live/data-platform-development/token"
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_data_platform_development_namespace" {
  provider = aws.analytical-platform-management-production

  secret_id = "cloud-platform/live/data-platform-development/namespace"
}
