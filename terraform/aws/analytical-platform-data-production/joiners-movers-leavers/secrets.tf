resource "aws_secretsmanager_secret" "govuk_notify_api_key" {
  # checkov:skip=CKV2_AWS_57:Reason for ignoring CKV2_AWS_57
  # checkov:skip=CKV2_AWS_149:Reason for ignoring CKV2_AWS_149
  name = "gov-uk-notify/production/api-key"
}

resource "aws_secretsmanager_secret" "jml_email" {
  # checkov:skip=CKV2_AWS_57:Reason for ignoring CKV2_AWS_57
  # checkov:skip=CKV2_AWS_149:Reason for ignoring CKV2_AWS_149
  name = "jml/email"
}
