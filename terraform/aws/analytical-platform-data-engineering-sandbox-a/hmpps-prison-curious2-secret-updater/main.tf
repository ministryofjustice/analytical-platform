data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "curious_sandbox_sas_bucket" {
  bucket = "prison-curious-sandbox-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "prison-curious-sandbox"
    Environment = "sandbox"
  }
}

resource "aws_secretsmanager_secret" "curious_sandbox_secret" {
  name = "/airflow/sandbox/prison-curious/test/curious-azure-credential"

  tags = {
    Environment = "sandbox"
  }
}

resource "aws_secretsmanager_secret_version" "initial" {
  secret_id     = aws_secretsmanager_secret.sandbox_secret.id
  secret_string = "initial-placeholder"
}

# module "prison_curious_secret_updater" {
#   source = "../modules/lambda-secret-updater"

#   lambda_name = "prison-curious2-secret-updater-sandbox"

#   bucket_name = "mojap-land"
#   object_key  = "hmpps/prison-curious/sas_token_info.txt"

#   secret_name = "/airflow/development/prison-curious/test/curious-azure-credential"
# }