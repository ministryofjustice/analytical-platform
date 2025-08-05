data "aws_iam_policy_document" "data_engineering_state_access" {
  statement {
    sid       = "S3ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.state_bucket.s3_bucket_arn]
  }
  statement {
    sid    = "S3ReadWriteBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${module.state_bucket.s3_bucket_arn}/aws/analytical-platform-data-engineering-production/*",
      "${module.state_bucket.s3_bucket_arn}/aws/analytical-platform-data-engineering-sandbox-a/*",
      "${module.state_bucket.s3_bucket_arn}/aws/analytical-platform-data-production/*"
    ]
  }
  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [module.state_locking.dynamodb_table_arn]
  }
}

module "data_engineering_state_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.59.0"

  name_prefix = "data-engineering-state-access"

  policy = data.aws_iam_policy_document.data_engineering_state_access.json
}
