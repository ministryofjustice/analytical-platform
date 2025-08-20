module "development_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.1.2"

  name            = "mojap-data-production-bold-egress-development"
  use_name_prefix = false

  trust_policy_permissions = {
    TrustS3AndIngestRoles = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = concat(
        [
          {
            type        = "Service"
            identifiers = ["s3.amazonaws.com"]
          }
        ]
      )
    }
  }

  policies = {
    custom = module.development_replication_iam_policy.arn
  }
}

module "production_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.1.2"

  name            = "mojap-data-production-bold-egress-production"
  use_name_prefix = false

  trust_policy_permissions = {
    TrustS3AndIngestRoles = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = concat(
        [
          {
            type        = "Service"
            identifiers = ["s3.amazonaws.com"]
          }
        ]
      )
    }
  }

  policies = {
    custom = module.production_replication_iam_policy.arn
  }
}
