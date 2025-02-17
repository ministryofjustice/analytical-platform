module "athena_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  create_role = true

  role_name         = "athena_spark_execution_role"
  role_requires_mfa = false

  trusted_role_arns = ["arn:aws:iam::${var.account_ids["data-platform-apps-and-tools-development"]}:root"]

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAthenaFullAccess",
    module.athena_iam_policy.arn
  ]
}