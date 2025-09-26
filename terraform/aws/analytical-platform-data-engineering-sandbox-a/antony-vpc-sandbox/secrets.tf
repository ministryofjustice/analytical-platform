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
  kms_key_id  = module.antony-vpc-sandbox-kms.key_arn
}

resource "aws_secretsmanager_secret_version" "vpc_master_user" {
  secret_id = aws_secretsmanager_secret.vpc_master_user.id
  secret_string = jsonencode({
    username = "rdsadmin"
    password = random_password.vpc_master_password.result
  })
}
