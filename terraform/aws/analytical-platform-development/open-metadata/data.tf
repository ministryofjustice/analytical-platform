data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_secretsmanager_secret_version" "auth0_domain" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/domain"
}

data "aws_secretsmanager_secret_version" "auth0_client_id" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/client-id"
}

data "aws_secretsmanager_secret_version" "auth0_client_secret" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/client-secret"
}

data "aws_secretsmanager_secret_version" "open_metadata_client_id" {
  secret_id = "open-metadata/azure/clientid"
}

data "aws_secretsmanager_secret_version" "open_metadata_tenant_id" {
  secret_id = "open-metadata/azure/tenantid"
}

data "aws_secretsmanager_secret_version" "openmetadata_airflow_rds_credentials" {
  secret_id = module.airflow_rds.db_instance_master_user_secret_arn

  depends_on = [module.airflow_rds]
}

data "aws_secretsmanager_secret_version" "openmetadata_rds_credentials" {
  secret_id = module.rds.db_instance_master_user_secret_arn

  depends_on = [module.rds]
}

data "aws_cloudwatch_event_bus" "auth0" {
  name = "aws.partner/auth0.com/alpha-analytics-moj-c855a398-59a4-44d3-b042-7873e5a9ba75/auth0.logs" // This was created by Auth0, we accepted it in the UI
}
