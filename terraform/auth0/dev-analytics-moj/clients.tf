resource "auth0_client" "visual_studio_code" {
  name                = "Visual Studio Code"
  app_type            = "regular_web"
  callbacks           = ["https://*-vscode.tools.dev.analytical-platform.service.justice.gov.uk/callback"]
  allowed_logout_urls = ["https://*-vscode.tools.dev.analytical-platform.service.justice.gov.uk"]
}
