# #tfsec:ignore:AVD-AWS-0098 CMK encryption is not required for this secret
# resource "aws_secretsmanager_secret" "analytical_platform_github_token" {
#   provider = aws.analytical-platform-management-production-eu-west-1
#   #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
#   #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
#   name        = "analytical-platform-github-token"
#   description = "Fine grained PAT for use in Analytical Platform"
#   kms_key_id  = "alias/aws/secretsmanager"
# }
