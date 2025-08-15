module "analytical_platform_infrastructure_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.1.0"

  name            = "analytical-platform-infrastructure-access"
  use_name_prefix = false

  trust_policy_permissions = {
    trusted_role_arns = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::509399598587:role/analytical-platform-github-actions"]
      }]
    }
  }

  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}
