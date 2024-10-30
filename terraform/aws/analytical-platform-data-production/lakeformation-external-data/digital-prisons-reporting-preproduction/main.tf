# Module: lake_formation_analytical_platform_data_prod
module "lake_formation_analytical_platform_data_prod" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-lakeformation?ref=0.5.0"


  providers = {
    aws.source      = aws.digital_prisons_reporting_preprod_eu_west_2
    aws.destination = aws
  }

  data_locations     = local.data_locations
  databases_to_share = local.databases
  #   tables_to_share = local.lakeformation_permissions
}
