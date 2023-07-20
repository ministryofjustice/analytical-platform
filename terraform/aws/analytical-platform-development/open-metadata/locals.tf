locals {
  openmetadata_airflow_rds_credentials = jsondecode(data.aws_secretsmanager_secret_version.openmetadata_airflow_rds_credentials.secret_string)
  openmetadata_rds_credentials         = jsondecode(data.aws_secretsmanager_secret_version.openmetadata_rds_credentials.secret_string)
  coder_rds_credentials                = jsondecode(data.aws_secretsmanager_secret_version.coder_rds_credentials.secret_string)

  datahub_namespace        = "datahub"
  datahub_service_accounts = ["datahub-datahub-frontend", "datahub-datahub-gms"]
}
