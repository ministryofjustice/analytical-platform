data "aws_iam_policy_document" "migration_replication_trigger_lambda_function" {
  # checkov:skip=CKV_AWS_356: S3 Batch Operations job ARNs require wildcard job ids (job/*) for create and status APIs.
  # checkov:skip=CKV_AWS_111: Required write actions are constrained to this account's S3 Batch job ARNs and pass-role restriction.

  statement {
    actions = [
      "s3:CreateJob",
      "s3:DescribeJob",
      "s3:UpdateJobStatus",
      "s3:ListJobs"
    ]

    resources = ["arn:aws:s3:*:${data.aws_caller_identity.current.account_id}:job/*"
    ]
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
      values   = ["s3.amazonaws.com"]
    }
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]

    resources = [
      module.rds_export.parquet_exports_bucket_arn,
      module.batch_manifest_bucket.bucket.arn
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${module.rds_export.parquet_exports_bucket_arn}/*",
      "${module.batch_manifest_bucket.bucket.arn}/*"
    ]
  }
}

module "migration_replication_trigger" {

  # Commit hash for v8.1.2
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=a7db1252f2c2048ab9a61254869eea061eae1318"

  function_name   = "${local.name}-${local.env}-migration-replication-trigger"
  description     = "Lambda to trigger S3 Batch Replication"
  handler         = "batch_replication_trigger.handler"
  runtime         = "python3.12"
  memory_size     = 512
  timeout         = 300
  architectures   = ["x86_64"]
  build_in_docker = false

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.migration_replication_trigger_lambda_function.json

  environment_variables = {
  
    ENVIRONMENT            = local.env
    ACCOUNT_ID             = data.aws_caller_identity.current.account_id
    BATCH_COPY_ROLE_ARN    = aws_iam_role.migration_replication.arn
    SOURCE_BUCKET_ARN      = module.rds_export.parquet_exports_bucket_arn
    DESTINATION_BUCKET_ARN = local.batch_destination_bucket_arn
    MANIFEST_BUCKET_ARN    = module.batch_manifest_bucket.bucket.arn
    CUTOFF_DATE            = coalesce(local.migration_replication_cutoff_date, "")
  }

  source_path = [{
    path = "${path.module}/lambda_functions/batch_replication_trigger.py"
  }]

  tags = var.tags
}
