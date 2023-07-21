data "aws_secretsmanager_secret" "auth0" {
  arn = "arn:aws:secretsmanager:eu-west-2:525294151996:secret:jupyterhub/auth0-crCf7P"
}

data "aws_secretsmanager_secret_version" "auth0" {
  secret_id = data.aws_secretsmanager_secret.auth0.id
}
