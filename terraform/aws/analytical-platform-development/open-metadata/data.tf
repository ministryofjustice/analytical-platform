data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_secretsmanager_secret_version" "open_metadata_client_id" {
  secret_id = "open-metadata/azure/clientid"
}

data "aws_secretsmanager_secret_version" "open_metadata_tenant_id" {
  secret_id = "open-metadata/azure/tenantid"
}
