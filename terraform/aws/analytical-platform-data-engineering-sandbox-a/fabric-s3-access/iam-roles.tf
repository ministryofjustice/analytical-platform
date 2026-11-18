module "fabric_iam_role" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/fabric-iam-role?ref=f1ac82228814d2fbdaf7d2d376f4d1531a0d78bf"

  object_id                          = local.object_id
  oidc_provider_arn                  = module.fabric_oidc_provider.arn
  oidc_provider_condition_key_prefix = module.fabric_oidc_provider.condition_key_prefix

  bucket_arn       = data.aws_s3_bucket.fabric_store.arn
  role_name        = "fabric-s3-access"
  role_policy_name = "fabric-s3-read-policy"
}
