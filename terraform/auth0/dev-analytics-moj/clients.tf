resource "auth0_client" "visual_studio_code" {
  name     = "Visual Studio Code"
  app_type = "regular_web"
  callbacks = [
    "https://*-vscode.tools.dev.analytical-platform.service.justice.gov.uk/callback",
    "https://*-vscode-tunnel.tools.dev.analytical-platform.service.justice.gov.uk/callback"
  ]
  allowed_logout_urls = [
    "https://*-vscode*.tools.dev.analytical-platform.service.justice.gov.uk",
    "https://*-vscode-tunnel.tools.dev.analytical-platform.service.justice.gov.uk",
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
  connection_id = "con_9AZZa8FvELBflX8B"
}
