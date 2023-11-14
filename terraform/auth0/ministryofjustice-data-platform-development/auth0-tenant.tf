/*
  As per the documentation for this resource (https://registry.terraform.io/providers/auth0/auth0/latest/docs/resources/tenant)
    > Creating tenants through the Management API is not currently supported.
    > Therefore, this resource can only manage an existing tenant created through the Auth0 dashboard.
  I (@jacobwoffenden) have imported this using the suggested mechanism from https://registry.terraform.io/providers/auth0/auth0/latest/docs/resources/tenant#import
    > terraform import auth0_tenant.this <UUID>
*/

resource "auth0_tenant" "this" {
  friendly_name         = "Ministry of Justice Data Platform Development"
  idle_session_lifetime = 72
  session_lifetime      = 168
  support_email         = "data-platform-tech@digital.justice.gov.uk"
  support_url           = "https://github.com/ministryofjustice/data-platform-support/issues/new/choose"
}
