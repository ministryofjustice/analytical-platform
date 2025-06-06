data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_canonical_user_id" "current" {}

data "aws_iam_role" "glue_policy_role" {
  for_each = toset(local.unique_role_names)
  name     = each.value
}

data "aws_iam_role" "data_engineering_glue_policy_role" {
  for_each = toset(local.data_engineering_unique_role_names)

  provider = aws.analytical-platform-data-engineering-production

  name = each.value
}

data "aws_iam_roles" "aws_sso_modernisation_platform_data_eng" {
  name_regex  = "AWSReservedSSO_modernisation-platform-data-eng_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_role" "aws_sso_modernisation_platform_data_eng" {
  name = one(data.aws_iam_roles.aws_sso_modernisation_platform_data_eng.names)
}
