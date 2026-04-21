locals {
  home_office_assume_role_principals = length(var.home_office_trusted_role_arns) > 0 ? var.home_office_trusted_role_arns : ["arn:aws:iam::${var.home_office_account_id}:root"]
}

data "aws_iam_policy_document" "home_office_source_s3_read" {
  count = var.home_office_copy_role_enabled ? 1 : 0

  statement {
    sid    = "ListAndLocation"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      for bucket_name in var.home_office_source_bucket_names : "arn:aws:s3:::${bucket_name}"
    ]
  }

  statement {
    sid    = "GetObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      for bucket_name in var.home_office_source_bucket_names : "arn:aws:s3:::${bucket_name}/*"
    ]
  }
}

module "home_office_source_s3_read" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = var.home_office_copy_role_enabled ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.1.0"

  name_prefix = "home-office-source-s3-read"
  description = "Read-only access to nominated source buckets for Home Office copy workloads"
  policy      = data.aws_iam_policy_document.home_office_source_s3_read[0].json
}

module "home_office_source_s3_read_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = var.home_office_copy_role_enabled ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.1.0"

  name            = var.home_office_copy_role_name
  use_name_prefix = false

  trust_policy_permissions = {
    TrustHomeOfficeToAssumeRole = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [
        for arn in local.home_office_assume_role_principals : {
          type        = "AWS"
          identifiers = [arn]
        }
      ]
    }
  }

  policies = {
    home_office_source_s3_read = module.home_office_source_s3_read[0].arn
  }
}
