data "aws_iam_policy_document" "openmetadata" {
  #checkov:skip=CKV_AWS_108:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_109:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_110:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_111:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179
  #checkov:skip=CKV_AWS_356:We are going to revisit this https://github.com/ministryofjustice/data-platform/issues/2179

  statement {
    sid    = "openmetadata"
    effect = "Allow"
    actions = [
      "s3:*",
      "athena:*",
      "glue:*"
    ]
    resources = ["*"]
  }
}

module "openmetadata_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 6.0"

  name_prefix = "openmetadata"

  policy = data.aws_iam_policy_document.openmetadata.json
}
