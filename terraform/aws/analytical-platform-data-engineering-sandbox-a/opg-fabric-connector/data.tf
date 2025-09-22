data "aws_iam_policy_document" "bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.opg_fabric_store.s3_bucket_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.opg_fabric_store.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "entra_bucket_access" {
  name   = "entra-bucket-access"
  role   = aws_iam_role.opg_fabric_access.id
  policy = data.aws_iam_policy_document.bucket_access.json
}


data "aws_secretsmanager_secret_version" "tenant_id_secret" {
  secret_id = aws_secretsmanager_secret.fabric_connector_tenant.id
}
data "aws_secretsmanager_secret_version" "object_id_secret" {
  secret_id = aws_secretsmanager_secret.fabric_connector_object.id
}
