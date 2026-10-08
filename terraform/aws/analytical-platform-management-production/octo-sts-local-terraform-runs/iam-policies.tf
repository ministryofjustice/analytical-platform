data "aws_iam_policy_document" "octo_sts_local_terraform" {
  statement {
    #checkov:skip=CKV_AWS_111: skip requires access to multiple resources
    #checkov:skip=CKV_AWS_356: GetWebIdentityToken does not support resource-level permissions
    sid       = "AllowOctoSTSWebIdentityToken"
    effect    = "Allow"
    actions   = ["sts:GetWebIdentityToken"]
    resources = ["*"]

    condition {
      # sts:IdentityTokenAudience is a multivalued key, so it requires a ForAnyValue/ForAllValues qualifier
      test     = "ForAnyValue:StringEquals"
      variable = "sts:IdentityTokenAudience"
      values   = ["octo-sts.dev"]
    }

    condition {
      test     = "NumericLessThanEquals"
      variable = "sts:DurationSeconds"
      values   = ["60"]
    }
  }

  statement {
    # blocks arbitrary custom claims being embedded in the minted token
    sid       = "DenyOctoSTSWebIdentityTokenTags"
    effect    = "Deny"
    actions   = ["sts:GetWebIdentityToken"]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:TagKeys"
      values   = ["false"]
    }
  }
}

module "octo_sts_local_terraform_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.2"

  name_prefix = "octo-sts-local-terraform"
  description = "Allows minting short-lived tokens exchanged with Octo STS for local Terraform runs"

  policy = data.aws_iam_policy_document.octo_sts_local_terraform.json
}
