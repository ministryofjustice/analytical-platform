module "create_a_derived_table_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.42.0"

  role_name = "create-a-derived-table"

  max_session_duration = 10800

  role_policy_arns = {
    policy = module.create_a_derived_table_iam_policy.arn
  }

  oidc_providers = {
    analytical-platform-compute-production = {
      provider_arn               = "arn:aws:iam::593291632749:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/801920EDEF91E3CAB03E04C03A2DE2BB"
      namespace_service_accounts = ["actions-runners:actions-runner-mojas-create-a-derived-table"]
    }
    cloud-platform = {
      provider_arn               = "arn:aws:iam::593291632749:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/DF366E49809688A3B16EEC29707D8C09"
      namespace_service_accounts = ["data-platform-production:actions-runner-mojas-create-a-derived-table"]
    }
    data-platform-production = {
      provider_arn               = "arn:aws:iam::593291632749:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/F147414004D7C4CF820F21F453AF80F1"
      namespace_service_accounts = ["actions-runners:actions-runner-mojas-create-a-derived-table"]
    }
  }
}
