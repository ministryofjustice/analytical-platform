data "aws_iam_policy_document" "ct-tact-list" {
  statement {
    sid       = "Allow"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/github-actions-infrastructure"]
  }
}

module "ct_tact_list_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.48.0"

  name_prefix = "ct-tact-list"

  policy = data.aws_iam_policy_document.ct-tact-list.json
}

module "ct-tact-list" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.48.0"

  role_name = "ct-tact-list"

  max_session_duration = 10800

  role_policy_arns = {
    policy = module.ct_tact_list_iam_policy.arn
  }

  oidc_providers = {
    analytical-platform-compute-production = {
      provider_arn = "arn:aws:iam::593291632749:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/801920EDEF91E3CAB03E04C03A2DE2BB"
      namespace_service_accounts = [
        "actions-runners:actions-runner-mojas-ct-tact-list",
      ]
    }
  }
}
