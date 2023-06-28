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

data "aws_secretsmanager_secret_version" "openmetadata_airflow_rds_credentials" {
  secret_id = "rds!db-5cf2a9f4-656e-43dc-bf22-2b78bc990bb2" /* TODO: This isn't outputted by the RDS module, should probably manage password ourselves */

  depends_on = [module.airflow_rds]
}

data "aws_secretsmanager_secret_version" "openmetadata_rds_credentials" {
  secret_id = "rds!db-75d4a9aa-d7c9-4992-bf44-93fc658ee7a7" /* TODO: This isn't outputted by the RDS module, should probably manage password ourselves */

  depends_on = [module.rds]
}
