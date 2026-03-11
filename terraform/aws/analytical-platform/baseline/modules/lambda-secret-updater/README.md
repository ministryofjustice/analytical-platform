# lambda-secret-updater

A Lambda function that reads an Azure SAS token file from S3 and updates an AWS Secrets Manager secret with the extracted URL. The file is deleted from S3 after successful processing.

## Usage

```hcl
module "prison_curious_secret_updater" {
  source = "../../analytical-platform/baseline/modules/lambda-secret-updater"

  lambda_name = "my-secret-updater"

  bucket_name = "my-bucket"
  object_key  = "hmpps/my-service/sas_token_info.txt"

  secret_name = "/airflow/prod/my-service/azure-credential"
}
```

The S3 file must contain a `SAS URL:` marker followed by the URL, with separator lines (`===`) and blank lines ignored. For example:

```
==============================================
SAS URL:
==============================================
https://example.blob.core.windows.net/container?sv=...
```

## S3 Trigger

To invoke the Lambda automatically when the file is uploaded, configure an S3 bucket notification and permission:

```hcl
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = module.my_secret_updater.lambda_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.my_bucket.arn
}

resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.my_bucket.id

  lambda_function {
    lambda_function_arn = module.my_secret_updater.lambda_arn
    events              = ["s3:ObjectCreated:Put"]
    filter_suffix       = "sas_token_info.txt"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `lambda_name` | Name of the Lambda function to create. | `string` | yes |
| `bucket_name` | Name of the S3 bucket containing the SAS token file. | `string` | yes |
| `object_key` | Full S3 object key path to sas_token_info.txt. | `string` | yes |
| `secret_name` | Name of the Secrets Manager secret to update (without ARN). | `string` | yes |

## Outputs

| Name | Description |
|------|-------------|
| `lambda_name` | The name of the Lambda function. |
| `lambda_arn` | The ARN of the Lambda function. |
