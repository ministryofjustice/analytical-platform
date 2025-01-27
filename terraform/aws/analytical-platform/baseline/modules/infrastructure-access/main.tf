module "analytical_platform_infrastructure_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.52.2"

  create_role = true

  role_name         = "analytical-platform-infrastructure-access"
  role_requires_mfa = false

  trusted_role_arns = ["arn:aws:iam::509399598587:role/analytical-platform-github-actions"]

  attach_admin_policy = true
}
