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
      "arn:aws:s3:::mojap-derived-tables",
      "arn:aws:s3:::dbt-query-dump/*",
      "arn:aws:s3:::dbt-query-dump",
      "arn:aws:s3:::mojap-manage-offences/ho-offence-codes/*",
      "arn:aws:s3:::mojap-manage-offences",
      "arn:aws:s3:::mojap-hub-exports/probation_referrals_dump/*",
      "arn:aws:s3:::mojap-hub-exports",
      "arn:aws:s3:::alpha-app-opg-lpa-dashboard",
      "arn:aws:s3:::alpha-app-opg-lpa-dashboard/dev/models/domain_name=opg/*",
      "arn:aws:s3:::alpha-app-opg-lpa-dashboard/prod/models/domain_name=opg/*"
    ]
  }
  statement {
    sid    = "DataAccess"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:GetObject*",
      "s3:GetBucket*"
    ]
    resources = [
      "arn:aws:s3:::*",
      "arn:aws:s3:::*/*"
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
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-production"]}:datacatalog/*",
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-production"]}:workgroup/*"
    ]
  }
  statement {
    sid    = "GlueAccess"
    effect = "Allow"
    actions = [
      "glue:Get*",
      "glue:DeleteTable",
      "glue:DeleteSchema",
      "glue:DeletePartition",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:UpdateSchema",
      "glue:UpdatePartition",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:CreateSchema",
      "glue:CreatePartition",
      "glue:CreatePartitionIndex",
      "glue:BatchCreatePartition",
      "glue:CreateDatabase"
    ]
    resources = [
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:schema/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:database/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:table/*/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:catalog"
    ]
  }
}

module "create_a_derived_table_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.33.0"

  name_prefix = "create-a-derived-table"

  policy = data.aws_iam_policy_document.create_a_derived_table.json
}
