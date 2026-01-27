data "aws_iam_policy_document" "copy_object" {
  statement {
    // Allow the lambda to read and copy the files from the land S3 bucket
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
    ]

    resources = [
      module.ppud_dev.s3_bucket_arn,
      "${module.ppud_dev.s3_bucket_arn}/*"
    ]
  }

  statement {
    // Allow the lambda to write the files to the bak upload S3 bucket
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]

    resources = [
      module.rds_export.backup_uploads_s3_bucket_arn,
      "${module.rds_export.backup_uploads_s3_bucket_arn}/*"
    ]
  }
}

module "copy_object" {
  # Commit hash for v8.1.2
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=a7db1252f2c2048ab9a61254869eea061eae1318"

  function_name   = "${local.name}-${local.env}-copy"
  description     = "Lambda to copy a file from the land bucket to bak upload bucket"
  handler         = "main.handler"
  runtime         = "python3.12"
  memory_size     = 1024
  timeout         = 900
  architectures   = ["x86_64"]
  build_in_docker = false

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.copy_object.json

  environment_variables = {
    LAND_BUCKET           = module.ppud_dev.s3_bucket_id
    BACKUP_UPLOADS_BUCKET = module.rds_export.backup_uploads_s3_bucket_id
    REGION                = data.aws_region.current.id
  }

  source_path = [{
    path = "${path.module}/lambda-functions/main.py"
  }]

  tags = var.tags
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.copy_object.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.ppud_dev.s3_bucket_arn
}

# Bucket Notification to trigger Lambda function
resource "aws_s3_bucket_notification" "land_bucket" {
  bucket = module.ppud_dev.s3_bucket_id

  lambda_function {
    lambda_function_arn = module.copy_object.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}
