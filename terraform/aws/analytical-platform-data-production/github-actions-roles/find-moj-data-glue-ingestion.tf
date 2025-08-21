data "aws_iam_policy_document" "find_moj_data_glue_ingestion" {
  statement {
    sid    = "GlueMetadataAccess"
    effect = "Allow"
    actions = [
      "glue:GetDatabases",
      "glue:GetTables"
    ]
    resources = [
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:catalog",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:database/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:table/*"
    ]
  }
}

module "find_moj_data_glue_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.1.0"

  name_prefix = "github-find-moj-data-glue-access"
  description = "IAM Policy"

  policy = data.aws_iam_policy_document.find_moj_data_glue_ingestion.json
}

module "find_moj_data_glue_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.1.0"

  enable_github_oidc = true

  name            = "github-find-moj-data-glue-access"
  use_name_prefix = false

  oidc_wildcard_subjects = ["ministryofjustice/data-catalogue:*"]

  policies = {
    github_find_moj_data_glue_access = module.find_moj_data_glue_access_iam_policy.arn
  }
}
