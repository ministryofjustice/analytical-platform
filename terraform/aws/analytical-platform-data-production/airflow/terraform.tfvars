##################################################
# General
##################################################

account_ids = {
  analytical-platform-data-production       = "593291632749"
  analytical-platform-development           = "525294151996"
  analytical-platform-management-production = "042130406152"
}

tags = {
  business-unit          = "Platforms"
  application            = "Data Platform"
  component              = "Airflow"
  environment            = "production"
  is-production          = "true"
  owner                  = "data-platform:data-platform-tech@digital.justice.gov.uk"
  infrastructure-support = "data-platform:data-platform-tech@digital.justice.gov.uk"
  source-code            = "github.com/ministryofjustice/data-platform/terraform/aws/analytical-platform-data-production/airflow"
}

##################################################
# Network
##################################################
vpc_cidr_block                    = "10.200.0.0/16"
noms_live_dead_end_cidr_block     = "10.40.0.0/18"
modernisation_platform_cidr_block = "10.26.0.0/15"
azs                               = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
private_subnet_cidrs              = ["10.200.20.0/24", "10.200.21.0/24", "10.200.22.0/24"]
public_subnet_cidrs               = ["10.200.10.0/24", "10.200.11.0/24", "10.200.12.0/24"]


transit_gateway_ids = {
  "airflow-dev-cloud-platform" = "tgw-009e14703041026a5"
  "airflow-dev-moj"            = "tgw-0e7b982ea47c28fba"
}
