module "coat_datasync_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.2.1"

  name            = "coat-datasync-iam-role"
  use_name_prefix = false

  trust_policy_permissions = {
    DataSync = {
      actions = [
        "sts:AssumeRole",
      ]
      principals = concat(
        [
          {
            type        = "Service"
            identifiers = ["datasync.amazonaws.com"]
          }
        ]
      )
    }
  }

  policies = {
    custom = module.coat_datasync_iam_policy.arn
  }
}
