##################################################
# Data Production
##################################################

module "data_production_infrastructure_access" {
  source = "./modules/infrastructure-access"

  providers = {
    aws                                = aws.analytical-platform-data-production-eu-west-2
    aws.platform_engineer_admin_source = aws.platform-engineer-admin-source-eu-west-2
  }
}
