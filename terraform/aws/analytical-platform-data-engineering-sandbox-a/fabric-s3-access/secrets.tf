module "tenant_id_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.1"

  name                  = "fabric-s3-access/tenant-id"
  description           = "Microsoft Entra tenant ID for Fabric S3 access"
  ignore_secret_changes = true
  secret_string         = var.default_tenant_value
}

module "object_id_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.1"

  name                  = "fabric-s3-access/object-id"
  description           = "Microsoft Entra object ID for Fabric S3 access"
  ignore_secret_changes = true
  secret_string         = var.default_object_value
}
