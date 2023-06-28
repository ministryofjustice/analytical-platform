locals {
  openmetadata_airflow_rds_credentials = jsondecode(data.aws_secretsmanager_secret_version.openmetadata_airflow_rds_credentials.secret_string)
  openmetadata_rds_credentials         = jsondecode(data.aws_secretsmanager_secret_version.openmetadata_rds_credentials.secret_string)
}
