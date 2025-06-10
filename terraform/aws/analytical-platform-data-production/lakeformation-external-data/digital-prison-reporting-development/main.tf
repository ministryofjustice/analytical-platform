# Module: lake_formation_analytical_platform_data_prod
# This created a share from the DPR dev account to the AP prod account 
# Shares were created for "data_locations" and "databases" in locals.tf
module "lake_formation_analytical_platform_data_prod" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-lakeformation?ref=6fab8677e457c2e276fa1feec8ee83bbccc1220a"


  providers = {
    aws.source      = aws.digital_prison_reporting_dev_eu_west_2
    aws.destination = aws
  }

  data_locations     = local.data_locations
  databases_to_share = local.databases
}


resource "aws_lakeformation_resource_link" "dpr_ap_integration_test_link" {
  provider        = aws.eu_west_1  
  name            = "test_table_1"            
  database_name   = "dpr_ap_integration_test_resource_link"
  target_table    = "test_table_1"                 
  target_database = "dpr-ap-integration-test"  
}
