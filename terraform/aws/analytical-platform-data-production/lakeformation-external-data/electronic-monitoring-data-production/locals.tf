locals {
  source_databases = [
    {
      source_name = "derived"
    },
    {
      source_name = "g4s_gps"
    }
  ]
  account_ids = jsondecode(data.aws_secretsmanager_secret_version.account_ids_version.secret_string)
}
