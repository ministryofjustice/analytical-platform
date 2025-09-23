module "tenant_id_secret" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager?ref=85977d132b8491281266ca412cee3e9ce7f2b457"

  name                  = "opg-fabric-connector/tenant-id"
  description           = "Tenant ID for OPG Fabric application"
  kms_key_id            = module.opg_kms_dev.key_arn
  ignore_secret_changes = true
  secret_string         = var.default_tenant_value
}

module "object_id_secret" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager?ref=85977d132b8491281266ca412cee3e9ce7f2b457"
  version = "1.3.1"

  name                  = "opg-fabric-connector/object-id"
  description           = "Object ID for OPG Fabric application"
  kms_key_id            = module.opg_kms_dev.key_arn
  ignore_secret_changes = true
  secret_string         = var.default_object_value
}
