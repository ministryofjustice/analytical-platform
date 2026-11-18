# depends_on ensures the secret version exists before this reads AWSCURRENT
data "aws_secretsmanager_secret_version" "tenant_id_secret" {
  secret_id  = module.tenant_id_secret.secret_arn
  depends_on = [module.tenant_id_secret]
}

data "aws_secretsmanager_secret_version" "object_id_secret" {
  secret_id  = module.object_id_secret.secret_arn
  depends_on = [module.object_id_secret]
}

# Existing bucket, managed elsewhere; referenced only to grant read access.
data "aws_s3_bucket" "fabric_store" {
  region = "eu-west-1"
  bucket = "cfe-fabric-sandbox"
}
