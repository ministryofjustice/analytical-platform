resource "aws_secretsmanager_secret" "ap-github-token" {
  name        = "/analytical-platform/ap-github-token"
  description = "Fine graind PAT for use in AP"
}
