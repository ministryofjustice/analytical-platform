data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_iam_role" "glue_policy_role" {
  for_each = toset(local.unique_role_names)
  name     = each.value
}