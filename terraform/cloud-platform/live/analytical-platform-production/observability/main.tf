resource "aws_secretsmanager_secret" "ap_github_token" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "/analytical-platform/ap-github-token"
  description = "Fine graind PAT for use in AP"
}
