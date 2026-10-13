data "aws_secretsmanager_secret_version" "tenant_id_secret" {
  secret_id = module.tenant_id_secret.secret_arn
}

data "aws_secretsmanager_secret_version" "object_id_secret" {
  secret_id = module.object_id_secret.secret_arn
}

# Existing bucket, managed elsewhere; referenced only to grant read access.
data "aws_s3_bucket" "fabric_store" {
  bucket = "cfe-fabric-sandbox"
}
