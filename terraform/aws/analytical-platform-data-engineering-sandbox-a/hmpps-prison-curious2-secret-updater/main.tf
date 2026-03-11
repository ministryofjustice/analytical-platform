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

# Create a secret (for testing)
resource "aws_secretsmanager_secret" "curious_sandbox_secret" {
  name = "/airflow/sandbox/prison-curious/test/curious-azure-credential"

  tags = {
    Environment = "sandbox"
  }
}

# The value to go in the secret
resource "aws_secretsmanager_secret_version" "initial" {
  secret_id     = aws_secretsmanager_secret.curious_sandbox_secret.id
  secret_string = "initial-placeholder"
}


# Create a lambda which takes the content of the bucket/object key and
# updates the secret with name secret_name
module "prison_curious_secret_updater" {
  source = "../../analytical-platform/baseline/modules/lambda-secret-updater"

  lambda_name = "prison-curious2-secret-updater-sandbox"

  bucket_name = aws_s3_bucket.curious_sandbox_sas_bucket.bucket
  object_key  = aws_s3_object.sas_token_file.key

  secret_name = aws_secretsmanager_secret.curious_sandbox_secret.name
}

# Allow s3 to invoke the lambda when the file is updated
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = module.prison_curious_secret_updater.lambda_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.curious_sandbox_sas_bucket.arn
}

# Configure S3 to invoke the Lambda when sas_token_info.txt
# is created or updated in hmpps/prison-curious/
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.curious_sandbox_sas_bucket.id

  lambda_function {
    lambda_function_arn = module.prison_curious_secret_updater.lambda_arn
    events              = ["s3:ObjectCreated:Put"]

    filter_suffix = aws_s3_object.sas_token_file.key
  }

  depends_on = [aws_lambda_permission.allow_s3]
}