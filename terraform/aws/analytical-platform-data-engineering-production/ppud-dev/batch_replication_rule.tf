resource "aws_s3_bucket_replication_configuration" "migration_replication" {

  bucket = module.rds_export.parquet_exports_bucket_arn
  role   = aws_iam_role.migration_replication.arn

  rule {
    id     = "migration-replication"
    status = "Disabled"

    filter {
      prefix = ""
    }

    destination {
      bucket = local.batch_destination_bucket_arn
    }

    delete_marker_replication {
      status = "Disabled"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.migration_replication]
}


data "aws_iam_policy_document" "migration_replication_trigger_lambda_function" {

  statement {
    actions = [
      "s3:CreateJob",
      "s3:DescribeJob",
      "s3:UpdateJobStatus",
      "s3:ListJobs"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [
      aws_iam_role.migration_replication.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["batchoperations.s3.amazonaws.com"]
    }
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]

    resources = [
      module.rds_export.parquet_exports_bucket_arn,
      aws_s3_bucket.batch_manifest.arn
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${module.rds_export.parquet_exports_bucket_arn}/*",
      "${aws_s3_bucket.batch_manifest.arn}/*"
    ]
  }
}

module "migration_replication_trigger" {

  # Commit hash for v8.1.2
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=a7db1252f2c2048ab9a61254869eea061eae1318"

  function_name   = "${local.name}-${var.tags["environment"]}-migration-replication-trigger"
  description     = "Lambda to trigger S3 Batch Replication"
  handler         = "main.handler"
  runtime         = "python3.12"
  memory_size     = 512
  timeout         = 300
  architectures   = ["x86_64"]
  build_in_docker = false

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.migration_replication_trigger_lambda_function.json

  environment_variables = {
    ACCOUNT_ID             = local.account_ids
    REPLICATION_ROLE_ARN   = aws_iam_role.migration_replication.arn
    SOURCE_BUCKET_ARN      = module.rds_export.parquet_exports_bucket_arn
    DESTINATION_BUCKET_ARN = local.batch_destination_bucket_arn
    MANIFEST_BUCKET_ARN    = aws_s3_bucket.batch_manifest.arn
    CUTOFF_DATE            = coalesce(local.migration_replication_cutoff_date, "")
  }

  source_path = [{
    path = "${path.module}/lambda_functions/migration_replication_trigger/batch_replication_trigger.py"
  }]

  tags = var.tags
}