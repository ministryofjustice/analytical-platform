module "data_engineering_state_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.59.0"


  create_role       = true
  role_name         = "data-engineering-state-access"
  role_requires_mfa = false

  trusted_role_arns = [
    "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_engineering_production_data_eng.names)}",
    "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_engineering_sandbox_a_admin.names)}",
    "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_engineering_sandbox_a_data_eng.names)}",
    "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_production_data_eng.names)}"
  ]

  custom_role_policy_arns = [module.data_engineering_state_access_iam_policy.arn]
}
