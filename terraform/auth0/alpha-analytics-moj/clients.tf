resource "auth0_client" "visual_studio_code" {
  name                = "Visual Studio Code"
  app_type            = "regular_web"
  callbacks           = ["https://*-vscode.tools.analytical-platform.service.justice.gov.uk/callback"]
  allowed_logout_urls = ["https://*-vscode.tools.analytical-platform.service.justice.gov.uk"]
}

resource "auth0_connection_client" "visual_studio_code_github" {
  client_id     = auth0_client.visual_studio_code.id
  connection_id = "con_RWgK9R3ISqKJLcZu"
}
