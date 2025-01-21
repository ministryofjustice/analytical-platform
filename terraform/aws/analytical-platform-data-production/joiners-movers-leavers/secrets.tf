module "jml_email_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name = "jml-report/email"

  ignore_secret_changes = true
  secret_string         = "CHANGEME"
}

module "govuk_notify_api_key_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name = "gov-uk-notify/api-key"

  ignore_secret_changes = true
  secret_string         = "CHANGEME"
}
