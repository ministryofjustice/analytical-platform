module "octo_sts_local_terraform_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.2"

  name            = "octo-sts-local-terraform"
  use_name_prefix = false

  trust_policy_permissions = {
    TrustAnalyticalPlatformTeamToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.analytical_platform_team_access_role.names)}"
        ]
      }]
    }
  }

  policies = {
    octo_sts_local_terraform = module.octo_sts_local_terraform_iam_policy.arn
  }
}
