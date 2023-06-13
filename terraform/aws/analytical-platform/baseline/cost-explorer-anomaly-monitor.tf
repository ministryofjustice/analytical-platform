##################################################
# Data Development
##################################################

module "data_development_cost_explorer_anomaly_monitor" {
  source = "./modules/cost-explorer-anomaly-monitor"

  providers = {
    aws.management = aws.management-production-eu-west-1
    aws.target     = aws.data-development-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["data-development"]["cost-explorer"]
}

##################################################
# Data Engineering Development
##################################################

/* Commenting out as Cost Explorer is already enabled in the account by PPDE
module "data_engineering_cost_explorer_anomaly_monitor" {
  source = "./modules/cost-explorer-anomaly-monitor"

  providers = {
    aws.management = aws.management-production-eu-west-1
    aws.target     = aws.data-engineering-production-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["data-engineering-production"]["cost-explorer"]
}
*/

##################################################
# Data Engineering Sandbox A
##################################################

module "data_engineering_sandbox_a_cost_explorer_anomaly_monitor" {
  source = "./modules/cost-explorer-anomaly-monitor"

  providers = {
    aws.management = aws.management-production-eu-west-1
    aws.target     = aws.data-engineering-sandbox-a-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["data-engineering-sandbox-a"]["cost-explorer"]
}


##################################################
# Data Production
##################################################

/* Commenting out as Cost Explorer is already enabled in the account by PPDE
module "data_production_cost_explorer_anomaly_monitor" {
  source = "./modules/cost-explorer-anomaly-monitor"

  providers = {
    aws.management = aws.management-production-eu-west-1
    aws.target     = aws.data-production-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["data-engineering-sandbox-a"]["cost-explorer"]
}
*/

##################################################
# Development
##################################################

module "development_cost_explorer_anomaly_monitor" {
  source = "./modules/cost-explorer-anomaly-monitor"

  providers = {
    aws.management = aws.management-production-eu-west-1
    aws.target     = aws.development-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["development"]["cost-explorer"]
}

##################################################
# Landing Production
##################################################

module "landing_production_cost_explorer_anomaly_monitor" {
  source = "./modules/cost-explorer-anomaly-monitor"

  providers = {
    aws.management = aws.management-production-eu-west-1
    aws.target     = aws.landing-production-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["landing-production"]["cost-explorer"]
}

##################################################
# Management Production
##################################################

module "management_production_cost_explorer_anomaly_monitor" {
  source = "./modules/cost-explorer-anomaly-monitor"

  providers = {
    aws.management = aws.management-production-eu-west-1
    aws.target     = aws.management-production-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["management-production"]["cost-explorer"]
}

##################################################
# Production
##################################################

module "production_cost_explorer_anomaly_monitor" {
  source = "./modules/cost-explorer-anomaly-monitor"

  providers = {
    aws.management = aws.management-production-eu-west-1
    aws.target     = aws.production-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["production"]["cost-explorer"]
}
