locals {

  ap_migration_apps  = jsondecode(file("../../configuration/ap_migration_apps.json"))
  migration_apps_map = { for app in local.ap_migration_apps : app.name => app } # so can be used in for_each

  # migration_apps_teams = [for app in local.ap_migration_apps : app.team]

  migration_apps_teams_map = {
    for team in toset(flatten([for app in local.ap_migration_apps : app.team])) : team => [for app in local.ap_migration_apps : app.name if contains(app.team, team)]
  }

  cloud_platform_eks_oidc_provider_arn = "arn:aws:iam::593291632749:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/DF366E49809688A3B16EEC29707D8C09"
  cloud_platform_eks_oidc_provider_id  = "oidc.eks.eu-west-2.amazonaws.com/id/DF366E49809688A3B16EEC29707D8C09"

  tags = {
    business-unit = "Platforms"
    project       = "analytical-platform-app-migration"
    owner         = "analytical-platform"
    is-production = "true"
    owner         = "analytical-platform: analytics-platform-tech@digital.justice.gov.uk"
    source-code   = "github.com/ministryofjustice/data-platform/tree/main/terraform/application-migration"
  }
}
