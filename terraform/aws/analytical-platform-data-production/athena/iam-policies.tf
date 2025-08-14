data "aws_iam_policy_document" "athena_spark" {
  #checkov:skip=CKV_AWS_108:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_109:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_110:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_111:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_356:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179

  statement {
    sid     = "DumpBucketAccess"
    effect  = "Allow"
    actions = ["s3:List*", "s3:*Object"]
    resources = [
      "arn:aws:s3:::dbt-query-dump/*",
      "arn:aws:s3:::dbt-query-dump"
    ]
  }
  statement {
    sid     = "MojapBucketAccess"
    effect  = "Allow"
    actions = ["s3:List*", "s3:*Object"]
    resources = [
      "arn:aws:s3:::mojap-derived-tables/prod/models/domain_name=development_sandpit/*",
      "arn:aws:s3:::mojap-derived-tables/sandpit/models/domain_name=development_sandpit/*",
      "arn:aws:s3:::mojap-derived-tables/dev/models/domain_name=development_sandpit/*",
      "arn:aws:s3:::alpha-everyone/athena-spark-packages/*"
    ]
  }
}

module "athena_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.0.0"

  name_prefix = "athena_spark"

  policy = data.aws_iam_policy_document.athena_spark.json
}
