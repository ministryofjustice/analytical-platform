##################################################
# Data Production
##################################################

module "data_production_infrastructure_access" {
  source = "./modules/infrastructure-access"

  providers = {
    aws = aws.analytical-platform-data-production-eu-west-2
  }
}
