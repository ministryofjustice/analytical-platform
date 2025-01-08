resource "aws_secretsmanager_secret" "govuk_notify_api_key" {
  # checkov:skip=CKV2_AWS_57:These won't be rotated in the traditional manner
  # checkov:skip=CKV_AWS_149:No KMS key needed as per above, these won't be rotated
  name = "gov-uk-notify/production/api-key"
}

resource "aws_secretsmanager_secret" "jml_email" {
  # checkov:skip=CKV2_AWS_57:These won't be rotated in the traditional manner
  # checkov:skip=CKV_AWS_149:No KMS key needed as per above, these won't be rotated
  name = "jml/email"
}
