resource "auth0_connection" "justiceuk_data_platform_auth0_ministryofjustice_production" {
  name         = "justiceuk-data-platform-auth0-ministryofjustice-production"
  display_name = "Ministry of Justice"
  strategy     = "waad"

  show_as_button = true

  options {
    identity_api                           = "microsoft-identity-platform-v2.0"
    domain                                 = "justiceuk.onmicrosoft.com"
    tenant_domain                          = "justiceuk.onmicrosoft.com"
    client_id                              = data.aws_secretsmanager_secret_version.entra_id_client_id.secret_string
    client_secret                          = data.aws_secretsmanager_secret_version.entra_id_client_secret.secret_string
    set_user_root_attributes               = "on_each_login"
    should_trust_email_verified_connection = "always_set_emails_as_verified"
    waad_protocol                          = "openid-connect"
  }
}
