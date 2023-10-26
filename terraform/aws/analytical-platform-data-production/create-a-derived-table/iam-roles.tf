module "create_a_derived_table_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.0"

  role_name = "create-a-derived-table"

  max_session_duration = 10800

  role_policy_arns = {
    policy = module.create_a_derived_table_iam_policy.arn
  }

  oidc_providers = {
    one = {
      provider_arn               = "arn:aws:iam::593291632749:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/DF366E49809688A3B16EEC29707D8C09"
      namespace_service_accounts = ["data-platform-production:gha-shr-mojas-create-a-derived-table"]
    }
  }
}
