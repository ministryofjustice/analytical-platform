#checkov:skip=CKV_TF_2:Module registry does not support tags for versions
module "tenant_id_secret" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.1"

  name                  = "opg-fabric-connector/tenant-id"
  description           = "Tenant ID for OPG Fabric application"
  ignore_secret_changes = true
  secret_string         = var.default_tenant_value
}

module "object_id_secret" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.1"

  name                  = "opg-fabric-connector/object-id"
  description           = "Object ID for OPG Fabric application"
  ignore_secret_changes = true
  secret_string         = var.default_object_value
}
