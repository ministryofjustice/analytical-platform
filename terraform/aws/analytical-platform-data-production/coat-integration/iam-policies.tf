data "aws_iam_policy_document" "glue_crawler_policy" {
  statement {
    sid       = "AllowS3KMSActions"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.coat_kms.key_arn]
  }
  statement {
    sid       = "AllowS3Actions"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.coat_s3.s3_bucket_arn}/*"]
  }
}

module "glue_crawler_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.59.0"

  name   = "${local.bucket_name}-glue-crawler"
  policy = data.aws_iam_policy_document.glue_crawler_policy.json
}
