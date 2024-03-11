# TODO look at using https://registry.terraform.io/modules/terraform-aws-modules/secrets-manager/aws/latest
resource "aws_secretsmanager_secret" "govuk_notify_api_key" {
  name        = "ingestion/sftp/govuk-notify/api-key"
  description = "This is Data Platform's GOV.UK Notify INTERNAL API key"
  kms_key_id  = module.govuk_notifiy_kms.key_arn
}

resource "aws_secretsmanager_secret" "govuk_notify_templates" {
  name       = "ingestion/sftp/govuk-notify/templates"
  kms_key_id = module.govuk_notifiy_kms.key_arn
}
