data "aws_iam_policy_document" "transfer_family_service_policy" {
  statement {
    sid    = "AllowCopyReadSource"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging"
    ]
    resources = ["${module.landing_bucket.s3_bucket_arn}/*"]
  }
  statement {
    sid    = "AllowCopyWriteDestination"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]
    resources = ["${module.landing_bucket.s3_bucket_arn}/*"]
  }
  statement {
    sid    = "AllowCopyList"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      module.landing_bucket.s3_bucket_arn,
      module.quarantine_bucket.s3_bucket_arn
    ]
  }
  statement {
    sid    = "AllowTag"
    effect = "Allow"
    actions = [
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging"
    ]
    resources = [
      "${module.landing_bucket.s3_bucket_arn}/*",
      "${module.quarantine_bucket.s3_bucket_arn}/*",
    ]
  }
  statement {
    sid    = "AllowDeleteSource"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion"
    ]
    resources = ["${module.landing_bucket.s3_bucket_arn}/*"]
  }
}

module "transfer_family_service_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name   = "${var.environment}-transfer-family-service-policy"
  policy = data.aws_iam_policy_document.transfer_family_service_policy.json

}
