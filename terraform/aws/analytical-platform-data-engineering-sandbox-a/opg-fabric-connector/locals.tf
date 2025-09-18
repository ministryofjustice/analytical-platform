locals {
  tenant-id = data.aws_secretsmanager_secret_version.tenant_id_secret.secret_id
}
locals {
  object-id = data.aws_secretsmanager_secret_version.object_id_secret.secret_id
}
