data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_secretsmanager_secret_version" "auth0_domain" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/ministryofjustice-data-platform-development/domain"
}

data "aws_secretsmanager_secret_version" "auth0_client_id" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/ministryofjustice-data-platform-development/client-id"
}

data "aws_secretsmanager_secret_version" "auth0_client_secret" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/ministryofjustice-data-platform-development/client-secret"
}

data "aws_secretsmanager_secret_version" "entra_id_tenant_id" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/ministryofjustice-data-platform-development/entra-id/tenant-id"
}

data "aws_secretsmanager_secret_version" "entra_id_client_id" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/ministryofjustice-data-platform-development/entra-id/client-id"
}

data "aws_secretsmanager_secret_version" "entra_id_client_secret" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/ministryofjustice-data-platform-development/entra-id/client-secret"
}
