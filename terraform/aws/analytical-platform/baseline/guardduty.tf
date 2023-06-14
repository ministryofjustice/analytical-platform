##################################################
# Data Development
##################################################

module "data_development_guardduty_eu_west_1" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-data-development-eu-west-1
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-data-development"]["guardduty"]
}

module "data_development_guardduty_eu_west_2" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-data-development-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-data-development"]["guardduty"]
}

##################################################
# Data Engineering Development
##################################################

module "data_engineering_guardduty_eu_west_1" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-data-engineering-production-eu-west-1
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-data-engineering-production"]["guardduty"]
}

module "data_engineering_guardduty_eu_west_2" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-data-engineering-production-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-data-engineering-production"]["guardduty"]
}

##################################################
# Data Engineering Sandbox A
##################################################

module "data_engineering_sandbox_a_guardduty_eu_west_1" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-data-engineering-sandbox-a-eu-west-1
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-data-engineering-sandbox-a"]["guardduty"]
}

module "data_engineering_sandbox_a_guardduty_eu_west_2" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-data-engineering-sandbox-a-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-data-engineering-sandbox-a"]["guardduty"]
}

##################################################
# Data Production
##################################################

module "data_production_guardduty_eu_west_1" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-data-production-eu-west-1
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-data-engineering-sandbox-a"]["guardduty"]
}

module "data_production_guardduty_eu_west_2" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-data-production-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-data-engineering-sandbox-a"]["guardduty"]
}

##################################################
# Development
##################################################

module "development_guardduty_eu_west_1" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-development-eu-west-1
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-development"]["guardduty"]
}

module "development_guardduty_eu_west_2" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-development-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-development"]["guardduty"]
}

##################################################
# Landing Production
##################################################

module "landing_production_guardduty_eu_west_1" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-landing-production-eu-west-1
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-landing-production"]["guardduty"]
}

module "landing_production_guardduty_eu_west_2" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-landing-production-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-landing-production"]["guardduty"]
}

##################################################
# Management Production
##################################################

module "management_production_guardduty_eu_west_1" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-management-production-eu-west-1
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-management-production"]["guardduty"]
}

module "management_production_guardduty_eu_west_2" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-management-production-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-management-production"]["guardduty"]
}

##################################################
# Production
##################################################

module "production_guardduty_eu_west_1" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-production-eu-west-1
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-production"]["guardduty"]
}

module "production_guardduty_eu_west_2" {
  source = "./modules/guardduty"

  providers = {
    aws.management = aws.analytical-platform-management-production-eu-west-1
    aws.target     = aws.analytical-platform-production-eu-west-2
  }

  pagerduty_service = var.pagerduty_services["analytical-platform-production"]["guardduty"]
}
