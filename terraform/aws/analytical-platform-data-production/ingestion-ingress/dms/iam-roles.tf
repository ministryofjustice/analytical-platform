module "dms_ingress_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.analytical_platform_ingestion_environments

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.1.1"

  name            = "mojap-data-production-dms-ingress-${each.key}"
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
        ],
        [
          for arn in each.value.ingest_trusted_role_arns : {
            type        = "AWS"
            identifiers = [arn]
          }
        ]
      )
    }
  }

  policies = {
    custom = module.dms_ingress_iam_policy[each.key].arn
  }
}
