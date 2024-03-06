module "ithc_iam_user" {
  for_each                      = nonsensitive(local.ithc_testers)
  version                       = "5.35.0"
  source                        = "terraform-aws-modules/iam/aws//modules/iam-user"
  name                          = each.value
  create_user                   = true
  create_iam_access_key         = false
  create_iam_user_login_profile = true
  force_destroy                 = true
  aws_iam_access_key_status     = "Inactive"

}

resource "aws_iam_group_membership" "ithc" {
  count = length(local.pentester_groups)
  name  = "${local.pentester_groups[count.index]}-membership"
  users = values(nonsensitive(local.ithc_testers))

  group = local.pentester_groups[count.index]
  depends_on = [
    module.ithc_iam_user
  ]

}
