data "aws_iam_policy_document" "data_eng_datalake_access" {
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
    ]
    resources = [
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:catalog",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:database/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:table/*"
    ]
  }
  statement {
    sid    = "LakeFormationAdminPermissions"
    effect = "Allow"
    actions = [
      "lakeformation:*"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "EditIAMPolicy"
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
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy"
    ]
    resources = ["arn:aws:iam::*:role/alpha*"]
  }
}

module "data_eng_datalake_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.58.0"

  name_prefix = "data-eng-datalake-access"

  policy = data.aws_iam_policy_document.data_eng_datalake_access.json
}

module "data_eng_datalake_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.58.0"

  name = "data-eng-datalake-access"

  subjects = ["ministryofjustice/data-engineering-datalake-access:*"]

  policies = {
    github_find_moj_data_glue_access = module.data_eng_datalake_access_iam_policy.arn
  }
}
