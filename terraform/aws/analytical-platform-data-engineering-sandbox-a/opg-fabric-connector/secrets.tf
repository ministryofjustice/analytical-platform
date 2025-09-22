resource "aws_kms_key" "secrets" {
  description         = "CMK for Secrets Manager (OPG)"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_for_secrets.json
  tags                = { Purpose = "SecretsManager" }
}

resource "aws_kms_alias" "secrets_alias" {
  name          = "alias/opg/secrets"
  target_key_id = aws_kms_key.secrets.key_id
}


module "tenant_id_secret" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name                  = "opg-fabric-connector/tenant-id"
  description           = "Tenant ID for OPG Fabric application"
  kms_key_id            = aws_kms_key.secrets.arn
  ignore_secret_changes = true
  secret_string         = var.default_tenant_value
}

module "object_id_secret" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name                  = "opg-fabric-connector/object-id"
  description           = "Object ID for OPG Fabric application"
  kms_key_id            = aws_kms_key.secrets.arn
  ignore_secret_changes = true
  secret_string         = var.default_object_value
}
