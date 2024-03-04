account_ids = {
  analytical-platform-data-engineering-sandbox-a = "684969100054"
  analytical-platform-management-production      = "042130406152"
}

tags = {
  business-unit          = "Platforms"
  application            = "Analytical Platform"
  component              = "sftp"
  environment            = "sandbox-a"
  is-production          = "false"
  owner                  = "data-platform:data-platform-tech@digital.justice.gov.uk"
  infrastructure-support = "data-platform:data-platform-tech@digital.justice.gov.uk"
  source-code            = "github.com/ministryofjustice/data-platform/terraform/aws/analytical-platform-data-engineering-sandbox-a/sftp"
}

##################################################
# VPC
##################################################

vpc_cidr                              = "10.69.0.0/16"
vpc_private_subnets                   = ["10.69.96.0/20", "10.69.112.0/20", "10.69.128.0/20"]
vpc_public_subnets                    = ["10.69.144.0/20", "10.69.160.0/20", "10.69.176.0/20"]
vpc_database_subnets                  = ["10.69.0.0/28", "10.69.0.16/28", "10.69.0.32/28"]
nat_gateway_bandwidth_alarm_threshold = 90
