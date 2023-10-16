data "aws_iam_policy_document" "create_a_derived_table" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:DeleteObject*",
      "s3:PutObject*"
    ]
    resources = [
      "arn:aws:s3:::mojap-derived-tables/*",
      "arn:aws:s3:::dbt-query-dump/*"
    ]
  }

  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "athena:List*",
      "athena:Get*",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:*:${data.aws_caller_identity.session.account_id}:datacatalog/*"
    ]
  }

  statement {
    sid    = "GlueAccess"
    effect = "Allow"
    actions = [
      "glue:GetDatabase*",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreatePartition",
      "glue:DeletePartition",
      "glue:CreateSchema",
      "glue:DeleteSchema"
    ]
    resources = [
      "arn:aws:glue:*:${data.aws_caller_identity.session.account_id}:schema/*",
      "arn:aws:glue:*:${data.aws_caller_identity.session.account_id}:database/*",
      "arn:aws:glue:*:${data.aws_caller_identity.session.account_id}:table/*/*",
    ]
  }
}

module "create_a_derived_table_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.30.0"

  name_prefix = "create-a-derived-table"

  policy = data.aws_iam_policy_document.create_a_derived_table.json
}
