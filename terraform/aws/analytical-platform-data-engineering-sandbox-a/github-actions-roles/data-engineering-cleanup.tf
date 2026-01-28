module "data_engineering_cleanup_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "6.1.2"

  name     = "data-engineering-cleanup"
  subjects = ["ministryofjustice/data-engineering-cleanup:*"]

  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}
