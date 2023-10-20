# this is deliberately bad, I'm testing trivy
#tfsec:ignore:AVD-GIT-0001 Ministry of Justice follows https://www.gov.uk/service-manual/technology/making-source-code-open-and-reusable
resource "github_repository" "bad" {
  name                 = "bad-repo"
  visibility           = "public"
  vulnerability_alerts = true
}
