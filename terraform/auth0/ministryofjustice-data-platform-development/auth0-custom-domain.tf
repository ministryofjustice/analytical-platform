resource "auth0_custom_domain" "main" {
  domain     = "auth.development.data-platform.service.justice.gov.uk"
  type       = "auth0_managed_certs"
  tls_policy = "recommended"
}
