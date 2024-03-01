module "ithc_iam_user" {
  for_each                      = nonsensitive(local.ithc_testers)
  version                       = "5.35.0"
  source                        = "terraform-aws-modules/iam/aws//modules/iam-user"
  name                          = each.value
  create_user                   = true
  create_iam_access_key         = true
  create_iam_user_login_profile = true
  force_destroy                 = true

}