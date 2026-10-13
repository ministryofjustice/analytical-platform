# Existing secrets, managed elsewhere; referenced only to read the GUID values.
data "aws_secretsmanager_secret_version" "tenant_id_secret" {
  secret_id = "fabric-s3-access/tenant-id"
}

data "aws_secretsmanager_secret_version" "object_id_secret" {
  secret_id = "fabric-s3-access/object-id"
}

# Existing bucket, managed elsewhere; referenced only to grant read access.
data "aws_s3_bucket" "fabric_store" {
  bucket = "cfe-fabric-sandbox"
}
