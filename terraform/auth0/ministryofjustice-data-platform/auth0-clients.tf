resource "auth0_client" "data_platform_control_panel" {
  name              = "data-platform-control-panel"
  app_type          = "regular_web"
  description       = "Data Platform Control Panel"
  logo_uri          = "https://assets.data-platform.service.justice.gov.uk/assets/justice-digital-logo.png"
  cross_origin_auth = true
}

resource "auth0_connection_client" "data_platform_control_panel_entra_id" {
  client_id     = auth0_client.data_platform_control_panel.id
  connection_id = auth0_connection.justiceuk_data_platform_auth0_ministryofjustice_production.id
}
