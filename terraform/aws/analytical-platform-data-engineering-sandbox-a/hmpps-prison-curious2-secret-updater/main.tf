data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "curious_sandbox_sas_bucket" {
  bucket = "prison-curious-sandbox-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "prison-curious-sandbox"
    Environment = "sandbox"
  }
}

# Create a test file
resource "aws_s3_object" "sas_token_file" {
  bucket = aws_s3_bucket.curious_sandbox_sas_bucket.id
  key    = "hmpps/prison-curious/sas_token_info.txt"

  content = <<EOT
==============================================
SAS URL:
==============================================
https://example.blob.core.windows.net/container?sv=test123
EOT

  content_type = "text/plain"
}

resource "aws_secretsmanager_secret" "curious_sandbox_secret" {
  name = "/airflow/sandbox/prison-curious/test/curious-azure-credential"

  tags = {
    Environment = "sandbox"
  }
}

resource "aws_secretsmanager_secret_version" "initial" {
  secret_id     = aws_secretsmanager_secret.curious_sandbox_secret.id
  secret_string = "initial-placeholder"
}

module "prison_curious_secret_updater" {
  source = "../../analytical-platform/baseline/modules/lambda-secret-updater"

  lambda_name = "prison-curious2-secret-updater-sandbox"

  bucket_name = aws_s3_bucket.curious_sandbox_sas_bucket.bucket
  object_key  = aws_s3_object.sas_token_file.key

  secret_name = aws_secretsmanager_secret.curious_sandbox_secret.name
}