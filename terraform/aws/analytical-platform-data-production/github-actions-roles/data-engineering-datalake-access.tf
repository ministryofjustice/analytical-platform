data "aws_iam_policy_document" "data_engineering_datalake_access" {
  statement {
    sid    = "GlueAccess"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateDatabase",
      "glue:UpdateDatabase",
      "glue:DeleteDatabase",
      "glue:GetTable",
      "glue:GetTables",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:CreatePartition",
      "glue:UpdatePartition",
      "glue:DeletePartition",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:BatchUpdatePartition",
      "glue:TagResource",
      "glue:unTagResource",
      "glue:GetTag",
      "glue:GetTags"
    ]
    resources = [
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:catalog",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:database/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:table/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:userDefinedFunction/*",
    ]
  }
  statement {
    sid       = "LakeFormationAdminPermissions"
    effect    = "Allow"
    actions   = ["lakeformation:*"]
    resources = ["*"]
  }
  statement {
    sid    = "IAMPolicyAccess"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy"
    ]
    resources = ["arn:aws:iam::*:policy/get-lf-data-access"]
  }
  statement {
    sid    = "IAMRoleAccess"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:UpdateAssumeRolePolicy",
      "iam:GetRole",
      "iam:UpdateRole"
    ]
    resources = ["arn:aws:iam::*:role/alpha*"]
  }
}

module "data_engineering_datalake_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.0.0"

  name_prefix = "data-engineering-datalake-access"
  description = "IAM Policy"

  policy = data.aws_iam_policy_document.data_engineering_datalake_access.json
}

module "data_engineering_datalake_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.0.0"

  name            = "data-engineering-datalake-access"
  use_name_prefix = false

  trust_policy_permissions = {
    trusted_role_arns = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-commons-production"]}:role/data-engineering-datalake-access-github-actions"]
      }]
    }
  }

  policies = {
    data_engineering_datalake_access = module.data_engineering_datalake_access_iam_policy.arn
  }
}
