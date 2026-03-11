data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  secret_arn = "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name}-*"

  s3_object_arn = "arn:aws:s3:::${var.bucket_name}/${var.object_key}"

  lambda_role_name   = "${var.lambda_name}-role"
  lambda_policy_name = "${var.lambda_name}-policy"
}
