data "aws_iam_policy_document" "athena_spark" {
  #checkov:skip=CKV_AWS_108:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_109:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_110:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_111:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_356:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179

  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "ListObjectsInBucket",
              "Effect": "Allow",
              "Action": ["s3:ListBucket"],
              "Resource": ["arn:aws:s3:::dbt-query-dump"]
          },
          {
              "Sid": "AllObjectActions",
              "Effect": "Allow",
              "Action": "s3:*Object",
              "Resource": ["arn:aws:s3:::dbt-query-dump/*"]
          }
      ]
  }
}

module "athena_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name_prefix = "athena_spark"

  policy = data.aws_iam_policy_document.athena_spark.json
}
