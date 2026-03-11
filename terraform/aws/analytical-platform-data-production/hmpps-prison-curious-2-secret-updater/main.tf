terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.9.0"
    }
  }
  required_version = "~> 1.5"
}

# Create a lambda which takes the content of the bucket/object key and
# updates the secret with name secret_name
module "hmpps_prison_curious2_secret_updater" {
  source = "./lambda-secret-updater"

  lambda_name = "hmpps-prison-curious2-secret-updater-apdp"

  bucket_name = "mojap-land"
  object_key  = "s3://mojap-land/hmpps/prison-curious//sas_token_info.txt"

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
