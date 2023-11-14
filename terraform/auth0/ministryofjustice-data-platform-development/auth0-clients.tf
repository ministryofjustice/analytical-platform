resource "auth0_client" "data_platform_control_panel" {
  name     = "data-platform-control-panel"
  app_type = "regular_web"
}

resource "auth0_connection_client" "data_platform_control_panel_entra_id" {
  client_id     = auth0_client.data_platform_control_panel.id
  connection_id = auth0_connection.justiceuk_data_platform_auth0_ministryofjustice_development.id
}
