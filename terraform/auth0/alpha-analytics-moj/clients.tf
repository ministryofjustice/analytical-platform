resource "auth0_client" "visual_studio_code" {
  name     = "Visual Studio Code"
  app_type = "regular_web"
  callbacks = [
    "https://*-vscode.tools.analytical-platform.service.justice.gov.uk/callback",
    "https://*-vscode-tunnel.tools.analytical-platform.service.justice.gov.uk/callback"
  ]
  allowed_logout_urls = [
    "https://*-vscode*.tools.analytical-platform.service.justice.gov.uk",
    "https://*-vscode-tunnel.tools.analytical-platform.service.justice.gov.uk",
  ]
  oidc_conformant   = true
  sso               = true
  cross_origin_auth = true
  jwt_configuration {
    alg = "HS256"
  }
}

resource "auth0_connection_client" "visual_studio_code_github" {
  client_id     = auth0_client.visual_studio_code.id
  connection_id = "con_RWgK9R3ISqKJLcZu"
}

resource "auth0_client" "dashboard_service" {
  name     = "Dashboard Service"
  app_type = "regular_web"
  callbacks = [
    "https://dashboards.analytical-platform.service.justice.gov.uk/callback/",
  ]
  allowed_logout_urls = [
    "https://dashboards.analytical-platform.service.justice.gov.uk/",
  ]
  oidc_conformant   = true
  sso               = true
  cross_origin_auth = true
  jwt_configuration {
    alg = "RS256"
  }
}

resource "auth0_connection_client" "dashboard_service_email" {
  client_id     = auth0_client.dashboard_service.id
  connection_id = "con_6zNyH9PCyBMhbCaD"
}
