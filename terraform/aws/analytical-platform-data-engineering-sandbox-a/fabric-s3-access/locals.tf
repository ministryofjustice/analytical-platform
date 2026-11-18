locals {
  tenant_id = trimspace(data.aws_secretsmanager_secret_version.tenant_id_secret.secret_string)
  object_id = trimspace(data.aws_secretsmanager_secret_version.object_id_secret.secret_string)
}
