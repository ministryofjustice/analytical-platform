resource "aws_secretsmanager_secret" "govuk_notify_api_key" {
  name = "gov-uk-notify/production/api-key"
}

resource "aws_secretsmanager_secret" "jml_email" {
  name = "jml/email"
}
