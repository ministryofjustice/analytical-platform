##################################################
# General
##################################################

account_ids = {
  analytical-platform-data-development            = "803963757240"
  analytical-platform-data-engineering-production = "189157455002"
  analytical-platform-data-engineering-sandbox-a  = "684969100054"
  analytical-platform-data-production             = "593291632749"
  analytical-platform-development                 = "525294151996"
  analytical-platform-landing-production          = "335823981503"
  analytical-platform-management-production       = "042130406152"
  analytical-platform-production                  = "312423030077"
}

tags = {
  business-unit          = "Platforms"
  application            = "Analytical Platform"
  component              = "Infrastructure baseline"
  is-production          = "true"
  owner                  = "analytical-platform:analytics-platform-tech@digital.justice.gov.uk"
  infrastructure-support = "analytical-platform:analytics-platform-tech@digital.justice.gov.uk"
  source-code            = "github.com/ministryofjustice/analytical-platform-infrastructure"
}

##################################################
# PagerDuty
##################################################

pagerduty_services = {
  analytical-platform-data-development = {
    guardduty     = "analytical-platform-security"
    cost-explorer = "data-platform"
  }
  analytical-platform-data-engineering-production = {
    guardduty     = "analytical-platform-security"
    cost-explorer = "data-platform"
  }
  analytical-platform-data-engineering-sandbox-a = {
    guardduty     = "analytical-platform-security"
    cost-explorer = "data-platform"
  }
  analytical-platform-data-production = {
    guardduty     = "analytical-platform-security"
    cost-explorer = "data-platform"
  }
  analytical-platform-development = {
    guardduty     = "analytical-platform-security"
    cost-explorer = "data-platform"
  }
  analytical-platform-landing-production = {
    guardduty     = "analytical-platform-security"
    cost-explorer = "data-platform"
  }
  analytical-platform-management-production = {
    guardduty     = "analytical-platform-security"
    cost-explorer = "data-platform"
  }
  analytical-platform-production = {
    guardduty     = "analytical-platform-security"
    cost-explorer = "data-platform"
  }
}
