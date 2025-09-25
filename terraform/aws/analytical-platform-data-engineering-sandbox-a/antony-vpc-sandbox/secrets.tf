resource "random_password" "vpc_master_password" {
  length  = 24
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "aws_secretsmanager_secret" "vpc_master_user" {
  name        = "antony-vpc-sandbox-master-user"
  description = "RDS export master user for antony-vpc-sandbox"
  tags        = var.tags
  kms_key_id  = var.kms_key_arn
}

resource "aws_secretsmanager_secret_rotation" "secret_rotator" {
  secret_id = aws_secretsmanager_secret.vpc_master_user.id
  rotation_lambda_arn = "arn:aws:lambda:eu-west-2:123456789012:function:secretsmanager-rotation-lambda-PostgreSQLSingleUser"
  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_secretsmanager_secret_version" "vpc_master_user" {
  secret_id = aws_secretsmanager_secret.vpc_master_user.id
  secret_string = jsonencode({
    username = "rdsadmin"
    password = random_password.vpc_master_password.result
  })
}
