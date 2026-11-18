module "fabric_oidc_provider" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/fabric-oidc-provider?ref=f1ac82228814d2fbdaf7d2d376f4d1531a0d78bf"

  tenant_id          = local.tenant_id
  oidc_provider_name = "fabric-s3-access"
}
