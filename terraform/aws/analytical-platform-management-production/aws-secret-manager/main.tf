#tfsec:ignore:AVD-AWS-0098 CMK encryption is not required for this secret
resource "aws_secretsmanager_secret" "ap_github_token" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "/aws-secrets-manager"
  description = "Fine graind PAT for use in AP"
  kms_key_id  = "alias/aws/secretsmanager"
}
